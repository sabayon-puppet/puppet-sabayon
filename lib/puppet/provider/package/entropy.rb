require 'puppet/provider/package'
require 'fileutils'

Puppet::Type.type(:package).provide :entropy, :parent => Puppet::Provider::Package do
  desc "Provides packaging support for Sabayon's entropy system."

  has_feature :versionable
  has_feature :installable
  has_feature :uninstallable
  has_feature :upgradeable

  commands :equo => "/var/lib/puppet/lib/puppet/provider/package/entropy/equo_locale"

  confine :has_entropy => true
  
  defaultfor :has_entropy => true

  def self.instances
    result_format = /^(\S+)\/(\S+)-([\.\d]+(?:_(?:alpha|beta|pre|rc|p)\d+)?(?:-r\d+)?)(?:#(\S+))?$/
        result_fields = [:category, :name, :ensure]

    begin
      search_output = equo "query", "list", "installed", "--quiet", "--verbose"

      packages = []
      search_output.each_line do |search_result|
        match = result_format.match(search_result)

        if match
          package = {}
          result_fields.zip(match.captures) do |field, value|
            package[field] = value unless !value or value.empty?
          end
          package[:provider] = :entropy
          packages << new(package)
        end
      end

      return packages
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail)
    end
  end

  def install
    should = @resource.should(:ensure)
    name = package_name
    unless should == :present or should == :latest
      # We must install a specific version
      name = "=#{name}-#{should}"
    end
    equo "install", name
  end

  # The common package name format.
  def package_name
    @resource[:category] ? "#{@resource[:category]}/#{@resource[:name]}" : @resource[:name]
  end

  def uninstall
    equo "remove", package_name
  end

  def update
    self.install
  end

  def query
    result_format = /^(\S+)\/(\S+)-([\.\d]+(?:_(?:alpha|beta|pre|rc|p)\d+)?(?:-r\d+)?)(?:#(\S+))?$/
    result_fields = [:category, :name, :version_available]

    begin
      search_output = equo "match", "--quiet", "--verbose", package_name
      search_output.chomp

      search_match = search_output.match(result_format)
      if search_match
        package = {}
        result_fields.zip(search_match.captures).each do |field, value|
          package[field] = value unless !value or value.empty?
        end

        installed_output = equo 'match', '--quiet', '--verbose', '--installed', package_name
        installed_output.chomp
        installed_match = installed_output.match(result_format)

        if installed_match
          installed_match_fields = Hash[result_fields.zip(installed_match.captures)]
          package[:ensure] = installed_match_fields[:version_available]
        else
          package[:ensure] = :absent
        end

        return package

      else
        not_found_value = "#{@resource[:category] ? @resource[:category] : "<unspecified category>"}/#{@resource[:name]}"
        raise Puppet::Error.new("No package found with the specified name [#{not_found_value}]")
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail)
    end
  end

  def latest
    self.query[:version_available]
  end
end