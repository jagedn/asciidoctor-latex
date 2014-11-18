
#
# File: latex-converter.rb
# Author: J. Carlson (jxxcarlson@gmail.com)
# Date: 9/26/2014
#
# This is a first step towards writing a LaTeX backend
# for Asciidoctor. It is based on the 
# Dan Allen's demo-converter.rb.  The "convert" method
# is unchanged, the methods "document node" and "section node" 
# have been redefined, and several new methods have been added.
#
# The main work will be in identifying asciidoc elements
# that need to be transformed and adding a method for
# each such element.  As noted below, the "warn" clause
# in the "convert" method is a useful tool for this task.
# 
# Usage: 
#
#   $ asciidoctor -r ./latex-converter.rb -b latex test/sample1.adoc
#
# Comments
#
#   1.  The "warn" clause in the converter code is quite useful.  
#       For example, you will discover in running the converter on 
#       "test/sample-1.adoc" that you have not implemented code for 
#       the "olist" node. Thus you can work through ever more complex 
#       examples to discover what you need to do to increase the coverage
#       of the converter. Hackish and ad hoc, but a process nonetheless.
#
#   2.  The converter simply passes on what it does not understand, e.g.,
#       LaTeX, This is good. However, we will have to map constructs
#       like"+\( a^2 = b^2 \)+" to $ a^2 + b^2 $, etc.
#       This can be done at the preprocessor level.
#
#   3.  In view of the preceding, we may need to chain a frontend
#       (preprocessor) to the backend. In any case, the main work 
#       is in transforming Asciidoc elements to TeX elements.
#       Other than the asciidoc ->  tex mapping, the tex-converter 
#       does not need to understand tex.
#
#   4.  Included in this repo are the files "test/sample1.adoc", "test/sample2.adoc",
#       and "test/elliptic.adoc" which can be used to test the code
#
#   5.  Beginning with version 0.0.2 we use a new dispatch mechanism
#       which should permit one to better manage growth of the code
#       as the coverage of the converter increases. Briefly, the 
#       main convert method, whose duty is to process nodes, looks
#       at node.node_name, then makes the method call node.tex_process
#       if the node_name is registered in NODE_TYPES. The method
#       tex_process is defined by extending the various classes to
#       which the node might belong, e.g., Asciidoctor::Block,
#       Asciidoctor::Inline, etc.  See the file "node_processor.rb",
#       where these extensions are housed for the time being.
#
#       If node.node_name is not found in NODE_TYPES, then
#       a warning message is issued.  We can use it as a clue
#       to find what to do to handle this node.  All the code
#       in "node_processors.rb" to date was written using this 
#       hackish process.
#
#
#  CURRENT STATUS
#
#  The following constructs are processed
#
#  * sections to a depth of five, e.g., == foo, === foobar, etc.
#  * ordered and unordered lists, though nestings is untested and
#    likely does not work.
#  * *bold* and _italic_
#  * hyperlinks like http://foo.com[Nerdy Stuff]
#


require 'asciidoctor'
require_relative 'colored_text'
require_relative 'node_processors'
require_relative 'tex_block'
require_relative 'click_block'
require_relative 'environment_block'
require_relative 'tex_preprocessor'
require_relative 'ent_to_uni'


include TeXBlock

require 'asciidoctor/converter/html5'

module Asciidoctor
  module LaTeX
    module Html5ConverterExtensions
      def environment node
        # simply add the "environment" role and delegate to the open block convert handler
        node.attributes['roles'] = (node.roles + ['environment']) * ' '
        self.open node
      end
      def click node
        # simply add the "environment" role and delegate to the open block convert handler
        node.attributes['roles'] = (node.roles + ['click']) * ' '
        self.open node
      end
    end
  end
end

class Asciidoctor::Converter::Html5Converter
  # inject our custom code into the existing Html5Converter class (Ruby 2.0 and above)
  prepend Asciidoctor::LaTeX::Html5ConverterExtensions
end                             


class LaTeXConverter
  
  include Asciidoctor::Converter
  register_for 'latex'
  

  Extensions.register do
    puts "Extensions.register)".magenta
    preprocessor TeXPreprocessor if document.basebackend? 'html'
    postprocessor EntToUni if document.basebackend? 'tex'
    block EnvironmentBlock
    block ClickBlock
  end


  Extensions.register :latex do
    puts "Extensions.register (2)".magenta
    # EnvironmentBlock
  end
  

  TOP_TYPES = %w(document section)
  LIST_TYPES = %w(olist ulist )        
  INLINE_TYPES = %w(inline_anchor inline_break inline_footnote inline_quoted)   
  BLOCK_TYPES = %w(admonition listing literal page_break paragraph stem pass open quote)
  OTHER_TYPES = %w(environment table)    
  NODE_TYPES = TOP_TYPES + LIST_TYPES + INLINE_TYPES + BLOCK_TYPES + OTHER_TYPES
    
  def initialize backend, opts
     puts "initialize".magenta
    super
    basebackend 'tex'
    outfilesuffix '.tex'
  end
  
  $latex_environment_names = [] 
  $label_counter = 0 
  
  def convert node, transform = nil
    
    puts "HOLA (1)".magenta
        
    if NODE_TYPES.include? node.node_name
      node.tex_process
    else
      warn %(Node to implement: #{node.node_name}, class = #{node.class}).magenta
      # This warning should not be switched off by $VERBOSE
    end 
    
  end
  
   
end