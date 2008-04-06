use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WordNet::Similarity::Visual',
    VERSION_FROM      => 'lib/WordNet/Similarity/Visual.pm',
    PREREQ_PM         => {'Gtk2'  => '1.0',
			  'Gnome2' => '1.0',
                          'WordNet::QueryData'  => '1.30',
                          'Text::Similarity'    => '0.02',
                          'WordNet::Similarity' => '0.14'},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WordNet/Similarity/Visual.pm', # retrieve abstract from module
       AUTHOR         => 'Saiyam Kohli <saiyamkohli at gmail.com>') : ()),
# allows make dist to create .tar.gz with correct name/version
   'dist'             => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
   # allows for automatic creation of META.yml
   ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
   ('LICENSE' => 'gpl', ) : ()),
);
