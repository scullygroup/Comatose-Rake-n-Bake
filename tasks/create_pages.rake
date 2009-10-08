require 'hpricot'
require 'titleizer'

# page creation tasks
namespace :create do
  namespace :page do
     
     desc 'Creates radiant pages from html sitemap generated from a Freemind mindmap.'
     task :fromhtml, :file_name, :needs => :environment do |t, args|
       #set the default filename to sitemap.html
       args.with_defaults(:file_name => "sitemap.html")
       parse_sitemap(args.file_name)
       
     end
     
     desc 'Creates a single radiant page as a child of the supplied path.'
     task :child, :name, :parent, :needs => :environment do |t, args|
        args.with_defaults(:name => "generated", :parent => "")
        existing_page = Page.find_by_url("/#{args.parent}#{slugify(args.name)}")
        
        # test if the page exists
        if !existing_page
          
          body_content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et lacus sit amet enim euismod commodo. Suspendisse sed arcu. Aliquam lacus. Ut ac ipsum. Fusce nunc odio, blandit vel, porttitor vitae, aliquam eget, felis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nam vitae ipsum. In urna. Donec ornare erat ullamcorper erat. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin bibendum nunc vitae neque. Nulla ultrices pulvinar metus. 

Phasellus turpis turpis, scelerisque sit amet, accumsan vel, sollicitudin a, elit. Pellentesque id erat in ante dictum convallis. Donec sed turpis vel leo blandit suscipit. In ligula urna, pellentesque nec, interdum pharetra, tincidunt a, dolor. Etiam cursus pharetra nisl. Ut aliquam, nisi id varius dignissim, orci ligula posuere nisi, vel vehicula metus elit vitae lorem. Cras urna quam, fermentum eu, aliquam sed, bibendum eget, lorem. Vestibulum congue. Integer blandit magna vitae dolor. Phasellus imperdiet vulputate nibh. Proin pellentesque. Aliquam pulvinar suscipit purus. Donec gravida volutpat nisl. Donec arcu. Curabitur mi ipsum, dapibus id, faucibus in, sagittis non, libero."

          parent = Page.find_by_url("/#{args.parent}")
          child = parent.children.build(:title => "#{titleify(args.name)}", :breadcrumb => "#{titleify(args.name)}", :slug => "#{slugify(args.name)}", :status_id => 100) 
          child.parts.build(:content => body_content, :name => "body")
          child.save!
          
          # let the user know the url was created
          puts "created page /#{args.parent}#{slugify(args.name)}/"
        else
          # let the user know that the url exists
          puts "page exists  /#{args.parent}#{slugify(args.name)}/"
        end
      end
      
      
      def parse_sitemap(file_name)
        # now load the file up in hpricot for parsing
        @doc = open("#{RAILS_ROOT}/public/#{file_name}"){ |f| Hpricot(f) }
        
        # get the base ul where the sitemap begins
        document = @doc.at('#base ul li').children_of_type('ul')
        
        # get the type of tag we need to search for
        div = (@doc/"#base/ul/li").search("div").first
        span = (@doc/"#base/ul/li").search("span").first
        
        tag =""
        
        if !div.nil?
          tag = div.name
        end
        
        if !span.nil?
          tag = span.name
        end
        
        # out put the name of the first tag
        puts "using first element of #{tag}";
        
        for ulparent in document
          search_ul(ulparent, '/', true, tag)
        end

      end

      def search_ul(item, path, ignore_first_level, title_tag)
        lis = item.children_of_type("li")
        
        for li in lis
          # create our title variables and find the span in the li to get the page title
          item_title = ""
          item_slug = ""
          spans = li.children_of_type("#{title_tag}")

          # get the titles and use the slugify and titleify to create sanitized page titles
          for span in spans
            item_slug = slugify(span.inner_text)
            item_title = titleify(span.inner_text)
            
            # puts "current tile tag #{item_slug} #{item_title}/"
            
          end
          
          # this block looks for only the item that matches primary-navigation its organized this way to match the way mindmap outputs xhtml
          if ignore_first_level && item_slug == "primary-navigation"
            lists = li.children_of_type("ul")
            for list in lists
              # recurse through primary navigations children with the given url path of / to match radients page structure
              search_ul(list, "/", false, title_tag)
            end
          else
            if !ignore_first_level           
              existing_page = Page.find_by_url("#{path}#{item_slug}")
              
              # test if the page exists
              if !existing_page
                # create some test body copy
                body_content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et lacus sit amet enim euismod commodo. Suspendisse sed arcu. Aliquam lacus. Ut ac ipsum. Fusce nunc odio, blandit vel, porttitor vitae, aliquam eget, felis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nam vitae ipsum. In urna. Donec ornare erat ullamcorper erat. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin bibendum nunc vitae neque. Nulla ultrices pulvinar metus. 

Phasellus turpis turpis, scelerisque sit amet, accumsan vel, sollicitudin a, elit. Pellentesque id erat in ante dictum convallis. Donec sed turpis vel leo blandit suscipit. In ligula urna, pellentesque nec, interdum pharetra, tincidunt a, dolor. Etiam cursus pharetra nisl. Ut aliquam, nisi id varius dignissim, orci ligula posuere nisi, vel vehicula metus elit vitae lorem. Cras urna quam, fermentum eu, aliquam sed, bibendum eget, lorem. Vestibulum congue. Integer blandit magna vitae dolor. Phasellus imperdiet vulputate nibh. Proin pellentesque. Aliquam pulvinar suscipit purus. Donec gravida volutpat nisl. Donec arcu. Curabitur mi ipsum, dapibus id, faucibus in, sagittis non, libero."

                # create the page
                parent = Page.find_by_url("#{path}")
                child = parent.children.build(:title => item_title, :breadcrumb => item_title, :slug => item_slug, :status_id => 100) 
                child.parts.build(:content => body_content, :name => "body")
                child.save!
                
                # output to show that we created the page and link to it
                puts "created page #{path}#{item_slug}/"
                
              else
                # output to show that we the page exists and show the path to it
                puts "page exists  #{path}#{item_slug}/"
              end
              
              # get the children of the page by ul
              lists = li.children_of_type("ul")

              # the loops through the li items in the ordered list to find each child page
              for list in lists
                search_ul(list, "#{path}#{item_slug.to_s}/", false, title_tag)
              end
            end
          end
        end

      end

      # slugify takes the content of the span and strips out all the special ()'d comments and makes a web friendly slug
      def slugify (urlstring)
        urlstring = urlstring.downcase.strip
        urlstring = urlstring.gsub(/\([A-Za-z0-9\.\s]*\)/, "")
        urlstring = urlstring.gsub(/[^A-Za-z0-9\s]/, "").strip
        urlstring = urlstring.gsub(/\s+/, "-")

        return urlstring
      end

      # titleify (its a dumb name I know but titleize is already used by rails and the gem I'm including ) strips out the
      # ()'s lowercases all word characters, and then formats the title in proper english via the titleize gem
      def titleify (urlstring)
        urlstring = urlstring.downcase.strip
        urlstring = urlstring.gsub(/\([A-Za-z0-9\.\s]*\)/, "")
        urlstring = urlstring.gsub(/[^A-Za-z0-9\-\s]/, "").strip
        urlstring = urlstring.gsub(/\s+/, " ")
        urlstring = urlstring.titleize

        return urlstring
      end

  end
end