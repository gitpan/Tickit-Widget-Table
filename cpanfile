requires 'parent', 0;
requires 'curry', 0;
requires 'Tickit', '>= 0.46';
requires 'Tickit::Widget', 0;
requires 'Adapter::Async', '>= 0.005';
requires 'String::Tagged', '>= 0.09';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
};

