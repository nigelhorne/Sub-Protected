# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Attribute::Handlers';
requires 'Carp';
requires 'Readonly';

on 'test' => sub {
	requires 'IPC::System::Simple';
	requires 'Test::Exception';
	requires 'Test::Most';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
