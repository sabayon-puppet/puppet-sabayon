Puppet::Type.newtype(:entropy_splitdebug) do
  @desc = "Manages splitdebug for packages in Entropy"
  
  ensurable
  
  newparam(:name) do
    desc "Unique name for this splitdebug specification"
  end

  newproperty(:operator) do
    desc "Operator that applies to the version. If not specified, defaults to '=' if a version is provided, not used if no version is provided"
  end

  newproperty(:package) do
    desc "Name of the package with splitdebug"
  end

  newproperty(:version) do
    desc "Version of the package"

    validate do |value|
      raise(ArgumentError, "") if value !~ /^(\d*(?:\.\d+[a-zA-Z]*)*)(?:_((?:alpha|beta|pre|rc)\d*))?(-r\d+)?$/
    end
  end

  newproperty(:slot) do
    desc "Slot the package is in"
  end

  newproperty(:use) do
    desc "Useflags for the package"
  end

  newproperty(:tag) do
    desc "Tag for the package"
  end

  newproperty(:repo) do
    desc "Repo for the package"
  end

  newproperty(:target) do
    desc "Location of the package.splitdebug file being managed"

    defaultto {
      if @resource.class.defaultprovider.ancestors.include?(Puppet::Provider::ParsedFile)
        @resource.class.defaultprovider.default_target
      else
        nil
      end
    }
  end

  validate do
    raise(ArgumentError, "At least one of package, tag or repo is required") if self[:package].nil? && self[:tag].nil? && self[:repo].nil?

    raise(ArgumentError, "Package is required when a version is specified") if self[:package].nil? && !self[:version].nil?

    raise(ArgumentError, "Version is required when an operator is specified") if self[:version].nil? && !self[:operator].nil?
  end

  autobefore(:package) do
    [self[:package]]
  end
end

# vim: set ts=2 sw=2 expandtab:

