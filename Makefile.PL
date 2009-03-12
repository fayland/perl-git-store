use inc::Module::Install;

name     'GitStore';
all_from 'lib/GitStore.pm';
author   'Fayland Lam <fayland@gmail.com>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

