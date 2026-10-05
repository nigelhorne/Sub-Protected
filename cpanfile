# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.010';

requires 'Attribute::Handlers';
requires 'B::Hooks::EndOfScope';
requires 'Carp';
requires 'Params::Get';
requires 'Params::Validate::Strict', '0.33';
requires 'Readonly';
requires 'Return::Set';
requires 'Sub::Identify';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';   # For TEST_REQUIRES
};

on 'test' => sub {
	requires 'Moo';
	requires 'Test::Memory::Cycle';
	requires 'Test::Most';
	requires 'Test::Returns';
	recommends 'Test::Mockingbird';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::CPAN::Changes';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
	requires 'Test::Version';
};
