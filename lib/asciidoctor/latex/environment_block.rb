# Test doc: samples/env.adoc

# EnvironmentBlock implements constructs of the form
#
# [env.TYPE]
# --
# foo, bar, etc.
# --
#
# e.g.,
#
# [env.theorem]
# --
# $2 + 2  = 4$. Cool!
# --
#
# TYPE can be anything, but certain values, e.g.,
# 'equation', 'equationalign', 'code' receive
# special handling.
#
# See  http://www.noteshare.io/section/environments
#
#
#


# OLD NOTES
#
# EnvironmentBlock is a first draft for a better
# way of handing a construct in Asciidoc that
# will map to LaTeX environments.  See
# issue #1 in asciidoctor/asciidoctor-latex.
#
# The code below is based on @mojavelinux's
# outline. The EnvironmentBlock is called
# into action (please ... give me a more
# precise phrase here!) when text
# of the form [env.foo] is encountered.
# This is the signal to create a block
# of type environment. (Is this correct?)
# and environment-type "foo"
#
# In the act of creating an environment
# block, information extracted from
# [env.foo] is used to title the block
# as "Foo n", where n is a counter for
# environments of type "foo".  The
# counter is created in a hash the first
# time an environment of that kind
# is encountered.  We set
#
#    counter["foo"] = 1
#
# Subsequent encounters cause the
# counter to be incremented.
#
# Later, when the backend process the AST,
# the information bundled by the
# EnvironmentBlock is used as is
# appropriate. In the case of conversion
# to LaTeX, the content of the block
# simply enclosed in delimiters as
# follows:
#
# \begin{foo} CONTENT \end{foo}
#
# Additionally, label information
# for cross-referencing is added at
# this stage.
#
# If, on the other hand, the backend
# is HTML, then the title (with numbering)
# that is extracted from [env.foo] is used
# to title the block.  Additional styling
# is added so as to conform to LaTeX
# conventions: the body of the block is
# italicized.

require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor/latex/core_ext/colored_string'


module Asciidoctor::LaTeX


  class EnvironmentBlock < Asciidoctor::Extensions::BlockProcessor

    use_dsl

    named :env
    on_context :open
    # parse_context_as :complex
    # ^^^ The above line gave me an error.  I'm not sure what do to with it.

    def process parent, reader, attrs

      warn "env: attributes = #{attrs}".yellow if $VERBOSE

      # Get orginal title if there is one
      if attrs['title']
        original_title =  attrs['title']
        attrs['original_title'] = original_title
      else
        original_title = nil
      end


      # Ensure that role is defined
      if attrs['role'] == nil
        role = 'item'
      else
        role = attrs['role']
      end

      if role.nil?
        puts 'role is NIL'.red
      else
        puts "role = #{role}".yellow
      end

      # fixme: this should not be necessary
      if attrs['role'] =~ /\\/
        attrs['role'] = attrs['role'].gsub(/\\/, '')
      end

      # Determine whether this is a numbered block
      # FIXME: what if there are several options?
      # Force the default for environments to be either numbered or not
      # e.g. 'box' not numbered, the others are numbered
      if attrs['options'].nil?
        if %w(box).include? role
          attrs['options'] = 'no-number'
        else
          attrs['options'] = 'numbered'
        end
      end


      env_name = role # roles.first # FIXME: roles.first is probably best
      if %w(equation equationalign chem).include? role
        attrs['title'] = env_name
      elsif role == 'code'
        attrs['title'] = 'Listing'
      elsif role == 'jsxgraph'
        attrs['title'] = 'JSXGraph'
      elsif role == 'box'
        attrs['title'] = ''
      else
        attrs['title'] = env_name.capitalize
      end
      env_title = attrs['title']


      if attrs['role'] == 'code'
        block = create_block parent, :listing, reader.lines, attrs
      else
        block = create_block parent, :environment, reader.lines, attrs
      end

      warn "document.references".blue + " #{parent.document.references}".cyan  if $VERBOSE
      warn "attrs['role'] = #{attrs['role']} and role = #{role}".red if $VERBOSE
      warn "id".red + " = #{attrs['id']}".yellow  if $VERBOSE

      if attrs['options']['numbered']
        warn "OPTIONS NUMBERED}".yellow  if $VERBOSE
        if env_name == 'equationalign'
          env_ref_prefix = 'equation'
        else
          env_ref_prefix = env_name
        end
        caption_num = parent.document.counter_increment("#{env_ref_prefix}-number", block)
        attrs['caption-num'] = caption_num
        caption = "#{caption_num}"
        if original_title
          attrs['title'] = "#{env_title} #{caption_num}: #{original_title}"
        else
          attrs['title'] = "#{env_title} #{caption_num}."
        end
        warn "eb: ".blue + "caption: #{caption}, title = #{attrs['title']}".magenta  if $VERBOSE
      else
        warn "OPTIONS NOT NUMBERED".yellow  if $VERBOSE
        if %w(box).include? role
          attrs['title'] = original_title
        else
          attrs['title'] = "#{env_title}"
        end
        warn "eb: ".blue + "caption: #{caption}, title = #{attrs['title']}".magenta  if $VERBOSE
      end

      if attrs['role'] == 'code'
        caption = nil
      end

      warn "attributes are now #{attrs}" if $VERBOSE

      block.assign_caption caption
      if %w(equation equationalign chem).include? role
        block.title = "#{caption_num}"
      elsif %w(box).include? role
          block.title =  attrs['title']
      else
        block.title = attrs['title']
      end
      block

    end

  end
end
