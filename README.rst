===============================
PHP accessor generation for VIM
===============================

This little plugin allows you to generate accessor methods (getter/setter) in
VIM for your PHP class attributes. It is based on vmustache__ which allows you
to write your own templates for accessors.

__ https://github.com/tobyS/vmustache

This plugin is inspired by `php_getset`__ but supports type annotations for
attributes in addition.

__ http://www.vim.org/scripts/script.php?script_id=1707

-------
Install
-------

You should install PDV through a VIM plugin manager of your choice. I recommend
Vundle__ for that purpose, but others should work, too. With Vundle you need

__ https://github.com/gmarik/vundle

::

    Bundle 'tobyS/php-accessors.vim'

in your ``.vimrc`` and then run ``:BundleInstall`` in a new VIM instance.

Before using PDV you must set the variable ``phpacc_template_dir`` which points
to your templates. You can use the default templates which should reside in
``~/.vim/bundles/php-accessors.vim/templates``.

Additionally, you can optionally configure ``phpacc_generate_functions`` which
is an array of accessor functions to be generated when you trigger the plugin.
An example would be::

    ["getter", "setter"]

This would always generate both accessors.

If you leave out this config variable, you will be asked which methods to
generate on usage.

Usage
-----

Bind the function ``phpacc#GenerateAccessors()`` to a key of your choice. The
function will work on single lines (where your cursor is) as well as on a range
of selected lines. A typical binding could be::

    nnoremap <buffer> <LocalLeader>i :call phpacc#GenerateAccessors()<CR>
    vnoremap <buffer> <LocalLeader>i :call phpacc#GenerateAccessors()<CR>

Roadmap
-------

The plugin is in a quite early stage. Points on the TODO list are:

- Avoid generation if method already exists
- Support additional accessors like ``isFoo()``, ``addItem()`` and so on
