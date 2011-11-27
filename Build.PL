
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => "0.88"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Table widget",
  "dist_author" => [
    "Tom Molesworth <tom\@entitymodel.com>"
  ],
  "dist_name" => "Tickit-Widget-Table",
  "dist_version" => "0.002",
  "license" => "perl",
  "module_name" => "Tickit::Widget::Table",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "List::UtilsBy" => 0,
    "Tickit" => "0.12",
    "parent" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
