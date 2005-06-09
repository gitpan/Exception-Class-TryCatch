use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Exception::Class::TryCatch',
      create_makefile_pl => 'traditional',
      create_readme => 1,
      license         => 'perl',	  
      requires => {
          perl => 5.005,
          Exception::Class => 1.20,
      },
      build_requires => {
          Test::Exception => 0.20,
          Test::More => 0.6, # (0.41 since perl 5.007003, 0.6 is new)
      },
	)->create_build_script;
