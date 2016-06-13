#!perl

use Test::Spec;
use Monorail::Bootstrapper;

describe 'A monorail bootstrapper' => sub {
    it 'compiles' => sub {
        pass();
    };
};

runtests;
