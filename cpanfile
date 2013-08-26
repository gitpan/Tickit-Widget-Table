requires 'parent', 0;
requires 'Mixin::Event::Dispatch', '>= 1.000';

requires 'Tickit', '>= 0.33';
requires 'Tickit::Widgets', '>= 0.10';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
};

