requires 'perl', '5.008';
requires 'Attribute::Handlers';
requires 'Carp';

on 'test' => sub {
    requires 'Test::Most';
    requires 'Test::Exception';
};
