brew install cpanm fswatch poppler

cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

cpanm --installdeps .
