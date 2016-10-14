# grovel-locally

Grovels as usual except that it builds the wrappers in a platform-specific system-local directory.

Where you usually use `:wrapper-file` you can use `:caching-wrapper-file` and in place of `:grovel-file` you can use `:caching-grovel-file`. You can then specify the directory local to the component that will be used to store the built files using `:cache-dir`.

For example:

    (:caching-wrapper-file "libspec" :soname "libnuklear" :cache-dir "cache")

Also adds the `include-local` spec directive which let's you include header files specified as `:static-file`s in your `.asd` file

## Note

This project (by design) builds thing locally to the system directory. There are very valid reasons you may want to avoid that. In those cases, don't use this.
