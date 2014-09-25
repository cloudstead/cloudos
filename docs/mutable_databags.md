

MANIFEST: defines the app in all cases. contains immutable data. declares data bag names/paths available to templates/manifest tasks.

DATA BAG: contains the actual value, referenced via some json path. may contain a "vendor" block declaring shasums for various json paths.
Only paths defined in the "vendor" block will be editable via the cloudos API.

RootyHandler: accepts requests to change a value. 
  - if the data bag or json path does not exist, error
  - if the json path was not declared in the manifest, error
  - the value is updated in the data bag

accepts request to view a value
  - if the data bag or json path does not exist, error
  - if the json path was not declared in the manifest, error
  - if the vendor section has no declaration for this setting, return the value
  - if the shasum of the value matches what is declared in the "vendor" section, return null
  - return the value

AllowSshHandler: determines if ssh access is allowed
  - walk all data bags, collect "vendor" settings that have "block_ssh" set to true
  - compare actual values in data bag with shasums in "vendor" part of databag