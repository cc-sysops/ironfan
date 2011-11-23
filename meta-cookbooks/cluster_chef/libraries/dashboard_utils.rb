require 'cgi'

module ClusterChef
  module DashboardUtils

    def add_dashboard_link(component, url_parts)
      if    url_parts.respond_to?(:each_pair) && url_parts[:url]
        url = url_parts[:url]
      elsif url_parts.respond_to?(:each_pair) && url_parts[:addr]
        port = url_parts[:dash_port] || url_parts[:port] || 80
        url = "http://#{CGI::escape(url_parts[:addr])}:#{port.to_i}"
      elsif url_parts.to_s =~ %r{^https?://}
        url = url_parts.to_s
      else
        return nil
      end
      node[:cluster_chef][:dashboard][:links][component] = url
    end

    # Index into a (potentially deep) hash, using each key in turn. The key can
    # be an array or dot-separated string.
    #
    # @example
    #   hsh = { 'a1' => { 'b2' => { 'c3' => 'hi', }, 'd2' => 'there' } }
    #   dotted_dereference(hsh, 'a1.b2.c3')  # 'hi'
    #   dotted_dereference(hsh, 'a1.d2')     # 'there'
    #   dotted_dereference(hsh, 'a1.b2')     # { :c3 => 'hi', }
    #   dotted_dereference(hsh, 'YARG.no')   # nil
    #   dotted_dereference(hsh, 'a1.d2.WTF') # nil
    #
    def deep_deref(hsh, key_parts)
      key_parts = key_parts.to_s.split(".") unless key_parts.respond_to?(:pop)
      last_key  = key_parts.last
      key_parts[0..-2].each{|key| hsh = hsh[key] rescue nil ; return unless hsh.respond_to?(:each_pair) }
      hsh[last_key]
    end

    # Given a hash, and keys
    #
    #   hsh = { 'a1' => { 'b2' => { 'c3' => 'hi', }, 'd2' => 'there' } }
    #   summary_rows(hsh, %w[ a1.b2.c3 a1.d2 a1.b2 WTF ])
    #
    # gives table rows
    #
    #   <tr><th>a1.b2.c3</th><td><pre>"hi"<pre></td></tr>
    #   <tr><th>a1.d2</th><td><pre>"there"<pre></td></tr>
    #   <tr><th>a1.b2</th><td><pre>{"b2"=&gt;{"c3"=&gt;"there"}}<pre></td></tr>
    #   <tr><th>WTF</th><td><pre>nil<pre></td></tr>
    #
    # Note that we're counting on you to supply the <table> and whatnot.
    def summary_rows(hsh, deep_keys)
      str = []
      deep_keys.each do |key|
        case key
        when /^==(.*)/ then str << %Q{<tr><th colspan="2"><h3>#{$1}</h3></td></tr>}
        when '----'    then str << %Q{<tr><td colspan="2"><hr/></td></tr>}
        else                str << %Q{<tr><th>#{CGI::escapeHTML(key)}</th><td>#{CGI::escapeHTML(deep_deref(node, key))}</td></tr>}
        end
      end
      str.join("\n      ")
    end

  end
end

class Chef::Recipe              ; include ClusterChef::DashboardUtils ; end
class Chef::Resource::Directory ; include ClusterChef::DashboardUtils ; end
class Chef::Resource::Execute   ; include ClusterChef::DashboardUtils ; end
class Chef::Resource::Template  ; include ClusterChef::DashboardUtils ; end
