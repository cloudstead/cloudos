# Application Management under CloudOs

The better part of CloudOs is devoted to managing and facilitating the applications you run on it.

There are many different applications. For the purposes of this document, they're all the same to us, but they
can exist in different states. For example:

* In the App Store: these apps are not installed but can be downloaded and made Available to your cloudstead.
* Downloaded: You've downloaded an app from the app store, but it's not yet installed. If it does require any initial setup, it will be immediately. Otherwise, you can install it by providing some first-time setup information.
* Active: these are apps that you have installed and that are running and available for your users
* Inactive: these apps are installed but are not running because you intentionally turned them off

Every app has a version, and backups are associated with a particular version of the app. 
When you install from a backup, the appropriate app version is installed.

    ~cloudos
      /app-repository
        /app-name                   # Everything for all versions of this app is here
          /metadata.json            # Contains meta-data about how the app is deployed in the cloudstead. More below.
          /app-version              # Everything for this version of the app is here
            /cloudos-manifest.json  # Tells CloudOs how to install/backup/restore the app
            /bundle.tar.gz          # The app bundle that was downloaded
            /plugin.jar             # Optional. If present, this provides the AppRuntime for CloudOs (single sign-on, etc)
            /chef                   # Chef overlay is here (defines cookbooks, data_bags)    

The metadata.json file contains a JSON object like this:

    {
      "active_version": "name-of-active-version",
      "installed_by": "account-name",
      "interactive": true
    }

If active_version is not present, or its value does not refer to a valid version, then the app will be disabled
The interactive field tells CloudOs whether the app has any web-accessible interfaces. Most apps will be interactive.
There are a handful of pure server-side apps that are not interactive, for example the email, web and database subsystems.

