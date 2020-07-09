brew install cpanm fswatch poppler haskell-stack

cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

cpanm --installdeps .

( cd vendor/duckling && stack build )
