use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Exception::Class::TryCatch',
      create_makefile_pl => 'passthrough',
      create_readme => 1,
      license         => 'perl',	  
      requires        => {
          perl => 5.005,
          Exception::Class => 1.19,
      },
	  build_requires  => { 
          Test::More => 0.54,
          Test::Exception => 0.19,
      },
	)->create_build_script;
