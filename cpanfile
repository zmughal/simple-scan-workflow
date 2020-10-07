requires 'Archive::Zip';
requires 'CLI::Osprey';
requires 'Capture::Tiny';
requires 'DBD::SQLite';
requires 'DBI';
requires 'Daemon::Control';
requires 'DateTime';
requires 'DateTime::Format::ISO8601';
requires 'Digest::SHA';
requires 'Dir::Self';
requires 'Encode';
requires 'File::Copy::Recursive';
requires 'File::Find::Rule';
requires 'File::Which';
requires 'File::chdir';
requires 'FindBin::libs';
requires 'IO::Compress::Zip';
requires 'IPC::Run';
requires 'IPC::System::Simple';
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'List::AllUtils';
requires 'List::Util', 'v1.55.0';
requires 'List::UtilsBy';
requires 'Log::Any';
requires 'Modern::Perl';
requires 'Moo';
requires 'Moo::Role';
requires 'MooX::HandlesVia';
requires 'MooX::ShortHas';
requires 'Mu';
requires 'Mu::Role';
requires 'Net::EmptyPort';
requires 'Net::FTP';
requires 'Net::Netrc';
requires 'Path::Tiny';
requires 'Readonly';
requires 'Regexp::Assemble';
requires 'ShellQuote::Any';
requires 'Sys::Filesystem';
requires 'Text::Template';
requires 'Try::Tiny';
requires 'Types::Path::Tiny';
requires 'YAML::XS';
requires 'autodie';
requires 'boolean';

if( $^O ne 'MSWin32' ) {
    requires 'File::Rsync';
}

on test => sub {
    requires 'Test::Class';
    requires 'Test::Most';
    requires 'parent';
    requires 'perl', 'v5.26.0';
};
