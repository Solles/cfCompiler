component accessors=true {

    function run(string pathToCompile="", string pathToCompileTo="", string serverName = '', boolean verbose = false) {
        var serverDetails ={};

        // If there's a name, check for a server with that name
		if( arguments.serverName.len() ) {
			serverDetails =  getInstance( 'serverService' ).resolveServerDetails( { name : arguments.serverName } );
		// If there's no serverName, check for a server in this working directory
		} else {
			serverDetails = getInstance( 'serverService' ).resolveServerDetails( { directory : shell.pwd() } );
		}

        var foundServerName = serverDetails.SERVERINFO.NAME;
        var serv = serverDetails.serverinfo.serverHomeDirectory.trim();

        var WEBINF = fileSystemUtil.resolvePath( "#serv#/WEB-INF" );
        var CFUSION_HOME = "#WEBINF#cfusion";

		var WWWROOT = command('server info')
			.params(name=foundServerName, property="webroot")
			.run(returnOutput=true, echo=arguments.verbose)
			.trim();

		var JAVA_HOME = command('server info')
			.params(name=foundServerName, property="javaHome")
			.run(returnOutput=true, echo=arguments.verbose)
			.trim();

		var JAVA_HOME_DIRECTORY = getDirectoryFromPath(JAVA_HOME);
		var JAVA_HOME_FILE = getFileFromPath(JAVA_HOME);

        var APP = fileSystemUtil.resolvePath( pathToCompile );
        var APP_COMPILED = fileSystemUtil.resolvePath( arguments.pathToCompileTo );

        if(!len(APP_COMPILED)) {
            APP_COMPILED = fileSystemUtil.resolvePath( "#pathToCompile#_compiled" );
        }

        var J2EEJAR = '';

		var j2eeJarDirectory = expandPath('#getInstance('HomeDir@constants')#/lib');
		var jarPaths = directoryList(j2eeJarDirectory, false, 'path', '*.jar', 'name desc', 'file');

		for (var path in jarPaths) {
			if (path contains 'runwar') {
				J2EEJAR = path;
				break;
			}
		}

		if (J2EEJAR == '') throw('J2EE Jar not found.');

        print.line("J2EEJAR: #J2EEJAR#")
            .line("CFUSION_HOME: #CFUSION_HOME#")
            .line("WEBINF: #WEBINF#")
            .line("APP: #APP#")
            .line("APP_COMPILED: #APP_COMPILED#")
            .line("WWWROOT: #WWWROOT#")
            .line("JAVA_HOME: #JAVA_HOME#").toConsole();

		command('run')
			.params('#JAVA_HOME_FILE# -cp "#J2EEJAR#;#WEBINF#/lib/cfmx_bootstrap.jar;#WEBINF#/lib/cfx.jar" -Dcoldfusion.classPath=#CFUSION_HOME#/lib/updates,#CFUSION_HOME#/lib -Dcoldfusion.libPath=#CFUSION_HOME#/lib coldfusion.tools.CommandLineInvoker Compiler -deploy -webinf #WEBINF# -webroot #WWWROOT# -cfroot #CFUSION_HOME# -srcdir #APP# -deploydir #APP_COMPILED#')
			.inWorkingDirectory(JAVA_HOME_DIRECTORY)
			.run(echo=arguments.verbose);
    }
}
