use strict;
use warnings;
use Test::Most;

use_ok 'Sub::Protected';
ok defined &Sub::Protected::_wrap,         '_wrap is defined';
ok defined &Sub::Protected::_check_access, '_check_access is defined';

done_testing;
