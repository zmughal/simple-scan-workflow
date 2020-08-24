package SSW::Data::BundleRoot;
# ABSTRACT: A model for data bundles stored under a bundle root folder

use Mu;
use Types::Path::Tiny qw(AbsPath AbsFile);
use File::Copy::Recursive;

use DBI;
use DBD::SQLite ();
use Digest::SHA;
use JSON::MaybeXS;

use IO::Compress::Zip qw(zip $ZipError) ;

use Readonly;
use Regexp::Assemble;
use if $^O ne 'MSWin32', "File::Rsync";

Readonly::Array  our  @FILE_EXTENSIONS_NOT_PDF => ( ".tiff", ".tif", ".jpg", ".jpeg" );
Readonly::Array  our  @FILE_EXTENSIONS_PDF => ( ".pdf" );
Readonly::Array  our  @FILE_EXTENSIONS => ( @FILE_EXTENSIONS_PDF, @FILE_EXTENSIONS_NOT_PDF );
Readonly::Scalar our  $FILE_EXTENSIONS_RE => Regexp::Assemble
	->new(anchor_line_end => 1 )
	->add( map { quotemeta } @FILE_EXTENSIONS );

use SSW::Data::Bundle;

=head1 DESCRIPTION

A bundle root is a folder which contains

=begin :list

* Bundles: folders that contain a file and the associated processing for that
  file.

  A bundle has the form such that its name matches the name of the file inside
  it. So a file named C<2020-06/letter.pdf> becomes bundle of the form
  (relative to the L</bundle_root_path>).

     bundle/2020-06--letter/
     |- 2020-06--letter.pdf
            (the original file)
     |- .archive.zip
            (contains the original file with the path 2020-06/letter.pdf)
     |- .steps/
            (contains processing intermediate steps)

* Metadata: contains information about the original files. This metadata
  includes:

=begin :list
* path to the source file relative to source top-level directory
* SHA-256 sum of the source file
* file modification time
=end :list

Note that if a bundle with the same name, but a different checksum already
exists, it will be saved with a different suffix.

=end :list

=cut

=attr bundle_root_path

Top-level directory for the bundle which contains the meta-data and bundle directory.

=cut
ro 'bundle_root_path', isa => AbsPath, coerce => 1;

=attr bundle_root_db_path

Path to the SQLite database for the bundle root.

=cut
lazy bundle_root_db_path => sub {
	my ($self) = @_;
	$self->bundle_root_path->child('.bundle.db');
}, isa => AbsPath;


lazy _bundle_path => sub {
	my ($self) = @_;
	$self->bundle_root_path->child('bundle');
}, isa => AbsPath;

# =attr _dbh
#
# Database handle for SQLite database at L</bundle_root_db_path>.
#
# =cut
lazy _dbh => sub {
	my ($self) = @_;
	my $dbh = DBI->connect("dbi:SQLite:@{[ $self->bundle_root_db_path ]}","","",
		{ RaiseError => 1, AutoCommit => 1 })
		or die "Could not connect: $DBI::errstr";
};

lazy _json => sub {
	my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
};

# =method _create_table
#
# Creates a table in the SQLite database.
#
# =cut
sub _create_table {
	my ($self) = @_;
	my $sql = <<'END_SQL';
CREATE TABLE IF NOT EXISTS source (
	id          INTEGER PRIMARY KEY      ,
	path        TEXT      NOT NULL       ,
	extension   TEXT      NOT NULL       ,
	mtime       INTEGER   NOT NULL       ,
	sha256      CHAR(64)  NOT NULL UNIQUE,
	bundle_name TEXT      NOT NULL UNIQUE
)
END_SQL

	$self->_dbh->do($sql);
}

lazy _sth_insert_bundle => sub {
	my ($self) = @_;
	$self->_dbh->prepare(q{
		INSERT INTO source
			(path, extension, mtime, sha256, bundle_name)
		VALUES  (   ?,         ?,     ?,      ?,           ?)
	});
};

lazy _sth_fetch_bundle_by_sha256 => sub {
	my ($self) = @_;
	$self->_dbh->prepare(q{
		SELECT
			path, extension, mtime, sha256, bundle_name
		FROM source
		WHERE sha256 = ?
	});
};


sub BUILD {
	my ($self) = @_;
	$self->bundle_root_path->mkpath;
	$self->_create_table;
}

sub _get_sha256_for_filename {
	my ($self, $filename) = @_;
	my $state = Digest::SHA->new(256);
	$state->addfile( "$filename", 'b' );
	$state->hexdigest;
}

sub bundles {
	...
}

sub create_or_find_bundle_for_file {
	my ($self, $file, $src_relative_to) = @_;

	if( $file !~ $FILE_EXTENSIONS_RE ) {
		die "File does not have extension: file: $file ; extensions: [ @FILE_EXTENSIONS ]";
	}

	if( ! $src_relative_to->realpath->subsumes($file->realpath) ) {
		die "File is not subsumed by source path: file: $file ; source: $src_relative_to";
	}

	my $sum = $self->_get_sha256_for_filename($file);

	my $bundle;
	if( my $data = $self->_dbh->selectrow_hashref($self->_sth_fetch_bundle_by_sha256, {}, $sum ) ) {
		my $final_path = $self->_path_for_bundle_name($data->{bundle_name});
		$bundle = SSW::Data::Bundle->new( bundle_path => $final_path,
			data => $data,
		);
	} else {
		$bundle = $self->_create_bundle( $file, $src_relative_to, $sum );
		$self->_sth_insert_bundle->execute(
			$bundle->data_path,
			$bundle->data_extension,
			$bundle->data_mtime,
			$bundle->data_sha256,
			$bundle->data_bundle_name
		);
	}

	return $bundle;
}

sub move_bundle {
	# TODO rename
	...
}

sub _path_for_bundle_name {
	my ($self, $bundle_name) = @_;
	$self->_bundle_path->child($bundle_name);
}

sub _bundle_name_exists {
	my ($self, $bundle_name) = @_;
	$self->_path_for_bundle_name($bundle_name)->exists;
}

sub _normalize_filename_for_bundle {
	my ($self, $filename) = @_;
	my $name = $filename->stringify; # uses Unix-style forward slash
	$name =~ s,/,--,g;
	$name =~ s/$FILE_EXTENSIONS_RE//;

	my $final_name = $name;

	my $suffix = 1;
	while( $self->_bundle_name_exists($final_name) ) {
		$final_name = sprintf("%s-%02d", $name, $suffix);
		$suffix++;
	}

	return $final_name;
}

=method _create_bundle

Given a file: e.g., C</path/to/process/bills-2020-06/IMG01.tiff>

=begin :list
* make the C<$src_relative_to = '/path/to/process/'>
* create bundle with name:
* put C<'$src_relative_to/bills-2020-06/IMG01.tiff'> in zip file with name
  C<'bills-2020-06/IMG01.tiff'>
* create bundle with name normalised (remove directory and extension)
  C<'bundle/bills-2020-06--IMG01'>
  valid extensions depend on what can be processed: .tiff, .tif, .pdf, .jpg, .jpeg
=end :list

=cut
sub _create_bundle {
	my ($self, $file, $src_relative_to, $sum) = @_;

	my $tmpdir = Path::Tiny->tempdir;

	my $file_rel = $file->relative($src_relative_to);
	my ($ext) = $file_rel =~ /($FILE_EXTENSIONS_RE)/; # includes the dot
	my $file_mtime = $file->stat->mtime;

	my $bundle_name = $self->_normalize_filename_for_bundle($file_rel);

	my $bundle_tmp_dir = $tmpdir->child($bundle_name);
	$bundle_tmp_dir->mkpath;

	if(0) {
		# Do not copy the original file into the bundle. We already have a copy
		# in the archive. This can be extracted as part of a step.
		#$file->copy( $bundle_tmp_dir->child("$bundle_name$ext") );
		#$bundle_tmp_dir->child("$bundle_name$ext")->touch( $file_mtime );
	}

	my $bundle_archive = $bundle_tmp_dir->child('.archive.zip');

	my $status = zip "$file" => "$bundle_archive",
		Name => "$file_rel",
		CanonicalName => 1,
		Efs => 1
		or die "zip failed: $ZipError\n";
	$bundle_archive->touch( $file_mtime );

	my $data = {
		'path' => "$file_rel",
		extension => $ext,
		mtime => $file_mtime,
		sha256 => $sum,
		bundle_name => $bundle_name,
	};

	my $bundle_meta = $bundle_tmp_dir->child('.meta.json');
	$bundle_meta->spew_utf8( $self->_json->encode( +{
		'-simple-scan-workflow' => { metadata_version => 1, },
		data => $data,
	}));

	my $final_path = $self->_path_for_bundle_name($bundle_name);



	if( $^O ne 'MSWin32' ) {
		my $obj = File::Rsync->new(
			archive      => 1,
			compress     => 1,
		);

		$obj->exec( src => $bundle_tmp_dir, dest => $final_path->parent )
			or die "Could not move directory: @{[ $obj->err ]}";
		# Note: $bundle_tmp_dir will be removed by tempdir so just copying is fine.
	} else {
		# TODO check if this preserves time stamps on Windows. It does
		# not on Unix-systems which is why C<File::Rsync> is a better
		# solution.
		File::Copy::Recursive::dirmove( $bundle_tmp_dir, $final_path )
			or die "Could not move directory: $!";
	}

	return SSW::Data::Bundle->new(
		bundle_path => $final_path,
		data => $data,
	);
}

1;
