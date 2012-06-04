package App::Parrot::Create;
use Dancer ':syntax';
use Dancer::Config;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Temp qw/tempfile tempdir/;
use File::Path qw/make_path/;
use autodie qw/:all/;
use File::Spec qw/catdir catfile/;
use Cwd;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

post '/submit' => sub {
    my ($name, $builder, $harness) = map { param($_) } qw/language_name builder test_harness/;

    $name =~ s/[^A-z]*//g;

    my $time             = time;
    my $tmp_base = tempdir( "app-parrot-create-XXXXXXX", TMPDIR => 1,
        # CLEANUP => 1
    );
    my $dir      = "$tmp_base/$time/$name";

    debug("Going to run bin/new_parrot_language.pl $name $dir");
    my @args = ($^X,"bin/new_parrot_language.pl",$name, $dir);
    system @args;

    my $zip        = Archive::Zip->new();
    my $dir_member = $zip->addDirectory("$dir/");

    debug("Going to write a zip file to $dir.zip");
    my $cwd = getcwd;
    my $archive_dir = config->{archive_dir} || catdir((config->{appdir},"public","tmp"));
    my $archive = catfile($archive_dir,"$time-$name.zip");
    unless ( $zip->writeToFileNamed($archive) == AZ_OK ) {
        die 'write error';
    }

    debug("Created $archive");

    template 'submit', {
        name    => $name,
        builder => $builder,
        harness => $harness,
        archive => $archive,
    };
};

true;
