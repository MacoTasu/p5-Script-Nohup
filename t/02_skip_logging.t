use strict;
use Test::More;
use Test::Mock::Guard;
use Path::Class;
use Test::SharedFork;

subtest "no touch logging file" => sub {
    my $tempdir = Path::Class::tempdir(CLEANUP => 1);

    my $guard = mock_guard(
        "Script::Nohup" => {
            _fork => sub {1},
            file  => sub { $tempdir->file("result.log") }
        },
    );

    my $script = tempfile($tempdir);
    my $pid = fork();
    if ($pid == 0) {
        sleep 1;
        kill "HUP", getppid;
        exit;
    }
    else {
        my $result = do $script;
        ok $result;
        ok !$tempdir->file("result.log")->open;
        is $guard->call_count("Script::Nohup","_fork"),1;
        is $guard->call_count("Script::Nohup","file"),0;
        waitpid($pid,0);
    }
};

sub tempfile {
    my $dir = shift;
    my $file = $dir->file("test_script_nohup.pl");
    my $fh = $file->openw;
    $fh->print(do{local $/;<DATA>});
    $fh->close;
    $file;
}

done_testing;
__DATA__
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Script::Nohup(
    skip_logging => 1
);

sleep 3;
print "hoge\n";

1;
