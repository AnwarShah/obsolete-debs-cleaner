# older-debs-cleaner
Remove older versions of local deb files

# How to run
You need ruby 1.9.3 or greater to run this script. In Ubuntu, install ruby with 
    sudo apt-get install ruby

Download the multi_version_remover.rb script and place it into the root directory of your .deb file dump. 

Then run the script in the terminal by calling it with `multi_version_remover.rb`


    Usage: multi_version_remover.rb [Options]...[FOLDER]
    Scan for .deb files recursively from current directory and
    prompt user to remove multiple versions
    
    All options are optional.
    If not specified, it will run with -s and `to_folder` folder name
    
    Options:
      -h    This help text
      -s    Present multiple versions in sorted order
    
    FOLDER is the user specified folder name. Default name is `to_delete`

# TO-DO
- Incorporate respective repository information along with file versions
- Add option to skip versions with a minimum size