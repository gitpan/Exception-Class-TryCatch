use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Exception::Class::TryCatch',
      license         => 'perl',	  
      requires        => {
          Exception::Class => 1.19,
      },
	  build_requires  => { 
          Test::Simple => 0.44,
          Test::Exception => 0.19,
      },
	)->create_build_script;
