# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Attribute::Handlers';
requires 'Carp';

on 'test' => sub {
	requires 'Test::Exception';
	requires 'Test::Most';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
