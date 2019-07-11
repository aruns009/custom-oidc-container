Puppet::Functions.create_function(:env) do
  dispatch :env do
    param 'String', :variable
  end

  def env(variable)
    ENV[variable]
  end
end
