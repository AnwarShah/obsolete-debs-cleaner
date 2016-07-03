# older-debs-cleaner
Remove older versions of local deb files

# How to run
You need ruby 1.9.3 or greater to run this script. In Ubuntu, install ruby with 
    sudo apt-get install ruby

You also need these packages in Ubuntu or similar in other distributions. `libapt-pkg-dev`, `swig2.0`, `libmagic-dev` Install these with 

    sudo apt-get install libapt-pkg-dev swig2.0 libmagic-dev

You Also need these gems in order to use the script `ruby-debian`, `libarchive-ruby-swig`. Install them with

    gem install ruby-debian libarchive-ruby-swig


Download the multi_version_remover.rb script and place it into the root directory of your .deb file dump. 

Then run the script in the terminal by calling it with `multi_version_remover.rb`


    Usage: multi_debs_remover.rb 
    Scan for .deb files recursively from current directory and
    prompt user to remove multiple versions
    
    
# TO-DO
- Incorporate respective repository information along with file versions
- Add option to skip versions with a minimum size
