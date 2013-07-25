require 'ffi'
require 'rbind/clang/clang_types'

module::Clang
module Rbind
  extend FFI::Library
  ffi_lib 'clang'
  
  # Provides the contents of a file that has not yet been saved to disk.
  # 
  # Each CXUnsavedFile instance provides the name of a file on the
  # system along with the current contents of that file that have not
  # yet been saved to disk.
  # 
  # = Fields:
  # :filename ::
  #   (String) The file whose contents have not yet been saved.
  #   
  #   This file must already exist in the file system.
  # :contents ::
  #   (String) A buffer containing the unsaved contents of this file.
  # :length ::
  #   (Integer) The length of the unsaved contents of this buffer.
  class UnsavedFile < FFI::Struct
    layout :filename, :string,
           :contents, :string,
           :length, :ulong
  end
  
  # Describes the availability of a particular entity, which indicates
  # whether the use of this entity will result in a warning or error due to
  # it being deprecated or unavailable.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:availability_kind).</em>
  # 
  # === Options:
  # :available ::
  #   The entity is available.
  # :deprecated ::
  #   The entity is available, but has been deprecated (and its use is
  #   not recommended).
  # :not_available ::
  #   The entity is not available; any use of it will be an error.
  # :not_accessible ::
  #   The entity is available, but not accessible; any use of it will be
  #   an error.
  # 
  # @method _enum_availability_kind_
  # @return [Symbol]
  # @scope class
  enum :availability_kind, [
    :available,
    :deprecated,
    :not_available,
    :not_accessible
  ]
  
  
  # Retrieve the character data associated with the given string.
  # 
  # @method get_c_string(string)
  # @param [String] string 
  # @return [String] 
  # @scope class
  attach_function :get_c_string, :clang_getCString, [String.by_value], :string
  
  # Free the given string,
  # 
  # @method dispose_string(string)
  # @param [String] string 
  # @return [nil] 
  # @scope class
  attach_function :dispose_string, :clang_disposeString, [String.by_value], :void
  
  # clang_createIndex() provides a shared context for creating
  # translation units. It provides two options:
  # 
  # - excludeDeclarationsFromPCH: When non-zero, allows enumeration of "local"
  # declarations (when loading any new translation units). A "local" declaration
  # is one that belongs in the translation unit itself and not in a precompiled
  # header that was used by the translation unit. If zero, all declarations
  # will be enumerated.
  # 
  # Here is an example:
  # 
  #   // excludeDeclsFromPCH = 1, displayDiagnostics=1
  #   Idx = clang_createIndex(1, 1);
  # 
  #   // IndexTest.pch was produced with the following command:
  #   // "clang -x c IndexTest.h -emit-ast -o IndexTest.pch"
  #   TU = clang_createTranslationUnit(Idx, "IndexTest.pch");
  # 
  #   // This will load all the symbols from 'IndexTest.pch'
  #   clang_visitChildren(clang_getTranslationUnitCursor(TU),
  #                       TranslationUnitVisitor, 0);
  #   clang_disposeTranslationUnit(TU);
  # 
  #   // This will load all the symbols from 'IndexTest.c', excluding symbols
  #   // from 'IndexTest.pch'.
  #   char *args() = { "-Xclang", "-include-pch=IndexTest.pch" };
  #   TU = clang_createTranslationUnitFromSourceFile(Idx, "IndexTest.c", 2, args,
  #                                                  0, 0);
  #   clang_visitChildren(clang_getTranslationUnitCursor(TU),
  #                       TranslationUnitVisitor, 0);
  #   clang_disposeTranslationUnit(TU);
  # 
  # This process of creating the 'pch', loading it separately, and using it (via
  # -include-pch) allows 'excludeDeclsFromPCH' to remove redundant callbacks
  # (which gives the indexer the same performance benefit as the compiler).
  # 
  # @method create_index(exclude_declarations_from_pch, display_diagnostics)
  # @param [Integer] exclude_declarations_from_pch 
  # @param [Integer] display_diagnostics 
  # @return [FFI::Pointer(Index)] 
  # @scope class
  attach_function :create_index, :clang_createIndex, [:int, :int], :pointer
  
  # Destroy the given index.
  # 
  # The index must not be destroyed until all of the translation units created
  # within that index have been destroyed.
  # 
  # @method dispose_index(index)
  # @param [FFI::Pointer(Index)] index 
  # @return [nil] 
  # @scope class
  attach_function :dispose_index, :clang_disposeIndex, [:pointer], :void
  
  # Retrieve the complete file and path name of the given file.
  # 
  # @method get_file_name(s_file)
  # @param [FFI::Pointer(File)] s_file 
  # @return [String] 
  # @scope class
  attach_function :get_file_name, :clang_getFileName, [:pointer], String.by_value
  
  # Retrieve the last modification time of the given file.
  # 
  # @method get_file_time(s_file)
  # @param [FFI::Pointer(File)] s_file 
  # @return [Integer] 
  # @scope class
  attach_function :get_file_time, :clang_getFileTime, [:pointer], :long
  
  # Determine whether the given header is guarded against
  # multiple inclusions, either with the conventional
  # #ifndef/#define/#endif macro guards or with #pragma once.
  # 
  # @method is_file_multiple_include_guarded(tu, file)
  # @param [TranslationUnitImpl] tu 
  # @param [FFI::Pointer(File)] file 
  # @return [Integer] 
  # @scope class
  attach_function :is_file_multiple_include_guarded, :clang_isFileMultipleIncludeGuarded, [TranslationUnitImpl, :pointer], :uint
  
  # Retrieve a file handle within the given translation unit.
  # 
  # @method get_file(tu, file_name)
  # @param [TranslationUnitImpl] tu the translation unit
  # @param [String] file_name the name of the file.
  # @return [FFI::Pointer(File)] the file handle for the named file in the translation unit \p tu,
  #   or a NULL file handle if the file was not a part of this translation unit.
  # @scope class
  attach_function :get_file, :clang_getFile, [TranslationUnitImpl, :string], :pointer
  
  # Identifies a specific source location within a translation
  # unit.
  # 
  # Use clang_getExpansionLocation() or clang_getSpellingLocation()
  # to map a source location to a particular file, line, and column.
  # 
  # = Fields:
  # :ptr_data ::
  #   (Array<FFI::Pointer(*Void)>) 
  # :int_data ::
  #   (Integer) 
  class SourceLocation < FFI::Struct
    layout :ptr_data, [:pointer, 2],
           :int_data, :uint
  end
  
  # Identifies a half-open character range in the source code.
  # 
  # Use clang_getRangeStart() and clang_getRangeEnd() to retrieve the
  # starting and end locations from a source range, respectively.
  # 
  # = Fields:
  # :ptr_data ::
  #   (Array<FFI::Pointer(*Void)>) 
  # :begin_int_data ::
  #   (Integer) 
  # :end_int_data ::
  #   (Integer) 
  class SourceRange < FFI::Struct
    layout :ptr_data, [:pointer, 2],
           :begin_int_data, :uint,
           :end_int_data, :uint
  end
  
  # Retrieve a NULL (invalid) source location.
  # 
  # @method get_null_location()
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_null_location, :clang_getNullLocation, [], SourceLocation.by_value
  
  # Determine whether two source locations, which must refer into
  # the same translation unit, refer to exactly the same point in the source
  # code.
  # 
  # @method equal_locations(loc1, loc2)
  # @param [SourceLocation] loc1 
  # @param [SourceLocation] loc2 
  # @return [Integer] non-zero if the source locations refer to the same location, zero
  #   if they refer to different locations.
  # @scope class
  attach_function :equal_locations, :clang_equalLocations, [SourceLocation.by_value, SourceLocation.by_value], :uint
  
  # Retrieves the source location associated with a given file/line/column
  # in a particular translation unit.
  # 
  # @method get_location(tu, file, line, column)
  # @param [TranslationUnitImpl] tu 
  # @param [FFI::Pointer(File)] file 
  # @param [Integer] line 
  # @param [Integer] column 
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_location, :clang_getLocation, [TranslationUnitImpl, :pointer, :uint, :uint], SourceLocation.by_value
  
  # Retrieves the source location associated with a given character offset
  # in a particular translation unit.
  # 
  # @method get_location_for_offset(tu, file, offset)
  # @param [TranslationUnitImpl] tu 
  # @param [FFI::Pointer(File)] file 
  # @param [Integer] offset 
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_location_for_offset, :clang_getLocationForOffset, [TranslationUnitImpl, :pointer, :uint], SourceLocation.by_value
  
  # Retrieve a NULL (invalid) source range.
  # 
  # @method get_null_range()
  # @return [SourceRange] 
  # @scope class
  attach_function :get_null_range, :clang_getNullRange, [], SourceRange.by_value
  
  # Retrieve a source range given the beginning and ending source
  # locations.
  # 
  # @method get_range(begin, end)
  # @param [SourceLocation] begin 
  # @param [SourceLocation] end 
  # @return [SourceRange] 
  # @scope class
  attach_function :get_range, :clang_getRange, [SourceLocation.by_value, SourceLocation.by_value], SourceRange.by_value
  
  # Determine whether two ranges are equivalent.
  # 
  # @method equal_ranges(range1, range2)
  # @param [SourceRange] range1 
  # @param [SourceRange] range2 
  # @return [Integer] non-zero if the ranges are the same, zero if they differ.
  # @scope class
  attach_function :equal_ranges, :clang_equalRanges, [SourceRange.by_value, SourceRange.by_value], :uint
  
  # Returns non-zero if \arg range is null.
  # 
  # @method range_is_null(range)
  # @param [SourceRange] range 
  # @return [Integer] 
  # @scope class
  attach_function :range_is_null, :clang_Range_isNull, [SourceRange.by_value], :int
  
  # Retrieve the file, line, column, and offset represented by
  # the given source location, as specified in a # line directive.
  # 
  # Example: given the following source code in a file somefile.c
  # 
  # #123 "dummy.c" 1
  # 
  # static int func(void)
  # {
  #     return 0;
  # }
  # 
  # the location information returned by this function would be
  # 
  # File: dummy.c Line: 124 Column: 12
  # 
  # whereas clang_getExpansionLocation would have returned
  # 
  # File: somefile.c Line: 3 Column: 12
  # 
  # @method get_presumed_location(location, filename, line, column)
  # @param [SourceLocation] location the location within a source file that will be decomposed
  #   into its parts.
  # @param [String] filename (out) if non-NULL, will be set to the filename of the
  #   source location. Note that filenames returned will be for "virtual" files,
  #   which don't necessarily exist on the machine running clang - e.g. when
  #   parsing preprocessed output obtained from a different environment. If
  #   a non-NULL value is passed in, remember to dispose of the returned value
  #   using \c clang_disposeString() once you've finished with it. For an invalid
  #   source location, an empty string is returned.
  # @param [FFI::Pointer(*UInt)] line (out) if non-NULL, will be set to the line number of the
  #   source location. For an invalid source location, zero is returned.
  # @param [FFI::Pointer(*UInt)] column (out) if non-NULL, will be set to the column number of the
  #   source location. For an invalid source location, zero is returned.
  # @return [nil] 
  # @scope class
  attach_function :get_presumed_location, :clang_getPresumedLocation, [SourceLocation.by_value, String, :pointer, :pointer], :void
  
  # Legacy API to retrieve the file, line, column, and offset represented
  # by the given source location.
  # 
  # This interface has been replaced by the newer interface
  # \see clang_getExpansionLocation(). See that interface's documentation for
  # details.
  # 
  # @method get_instantiation_location(location, file, line, column, offset)
  # @param [SourceLocation] location 
  # @param [FFI::Pointer(*File)] file 
  # @param [FFI::Pointer(*UInt)] line 
  # @param [FFI::Pointer(*UInt)] column 
  # @param [FFI::Pointer(*UInt)] offset 
  # @return [nil] 
  # @scope class
  attach_function :get_instantiation_location, :clang_getInstantiationLocation, [SourceLocation.by_value, :pointer, :pointer, :pointer, :pointer], :void
  
  # Retrieve the file, line, column, and offset represented by
  # the given source location.
  # 
  # If the location refers into a macro instantiation, return where the
  # location was originally spelled in the source file.
  # 
  # @method get_spelling_location(location, file, line, column, offset)
  # @param [SourceLocation] location the location within a source file that will be decomposed
  #   into its parts.
  # @param [FFI::Pointer(*File)] file (out) if non-NULL, will be set to the file to which the given
  #   source location points.
  # @param [FFI::Pointer(*UInt)] line (out) if non-NULL, will be set to the line to which the given
  #   source location points.
  # @param [FFI::Pointer(*UInt)] column (out) if non-NULL, will be set to the column to which the given
  #   source location points.
  # @param [FFI::Pointer(*UInt)] offset (out) if non-NULL, will be set to the offset into the
  #   buffer to which the given source location points.
  # @return [nil] 
  # @scope class
  attach_function :get_spelling_location, :clang_getSpellingLocation, [SourceLocation.by_value, :pointer, :pointer, :pointer, :pointer], :void
  
  # Retrieve a source location representing the first character within a
  # source range.
  # 
  # @method get_range_start(range)
  # @param [SourceRange] range 
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_range_start, :clang_getRangeStart, [SourceRange.by_value], SourceLocation.by_value
  
  # Retrieve a source location representing the last character within a
  # source range.
  # 
  # @method get_range_end(range)
  # @param [SourceRange] range 
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_range_end, :clang_getRangeEnd, [SourceRange.by_value], SourceLocation.by_value
  
  # Describes the severity of a particular diagnostic.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:diagnostic_severity).</em>
  # 
  # === Options:
  # :ignored ::
  #   A diagnostic that has been suppressed, e.g., by a command-line
  #   option.
  # :note ::
  #   This diagnostic is a note that should be attached to the
  #   previous (non-note) diagnostic.
  # :warning ::
  #   This diagnostic indicates suspicious code that may not be
  #   wrong.
  # :error ::
  #   This diagnostic indicates that the code is ill-formed.
  # :fatal ::
  #   This diagnostic indicates that the code is ill-formed such
  #   that future parser recovery is unlikely to produce useful
  #   results.
  # 
  # @method _enum_diagnostic_severity_
  # @return [Symbol]
  # @scope class
  enum :diagnostic_severity, [
    :ignored, 0,
    :note, 1,
    :warning, 2,
    :error, 3,
    :fatal, 4
  ]
  
  # Determine the number of diagnostics produced for the given
  # translation unit.
  # 
  # @method get_num_diagnostics(unit)
  # @param [TranslationUnitImpl] unit 
  # @return [Integer] 
  # @scope class
  attach_function :get_num_diagnostics, :clang_getNumDiagnostics, [TranslationUnitImpl], :uint
  
  # Retrieve a diagnostic associated with the given translation unit.
  # 
  # @method get_diagnostic(unit, index)
  # @param [TranslationUnitImpl] unit the translation unit to query.
  # @param [Integer] index the zero-based diagnostic number to retrieve.
  # @return [FFI::Pointer(Diagnostic)] the requested diagnostic. This diagnostic must be freed
  #   via a call to \c clang_disposeDiagnostic().
  # @scope class
  attach_function :get_diagnostic, :clang_getDiagnostic, [TranslationUnitImpl, :uint], :pointer
  
  # Destroy a diagnostic.
  # 
  # @method dispose_diagnostic(diagnostic)
  # @param [FFI::Pointer(Diagnostic)] diagnostic 
  # @return [nil] 
  # @scope class
  attach_function :dispose_diagnostic, :clang_disposeDiagnostic, [:pointer], :void
  
  # Options to control the display of diagnostics.
  # 
  # The values in this enum are meant to be combined to customize the
  # behavior of \c clang_displayDiagnostic().
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:diagnostic_display_options).</em>
  # 
  # === Options:
  # :display_source_location ::
  #   Display the source-location information where the
  #   diagnostic was located.
  #   
  #   When set, diagnostics will be prefixed by the file, line, and
  #   (optionally) column to which the diagnostic refers. For example,
  #   
  #   \code
  #   test.c:28: warning: extra tokens at end of #endif directive
  #   \endcode
  #   
  #   This option corresponds to the clang flag \c -fshow-source-location.
  # :display_column ::
  #   If displaying the source-location information of the
  #   diagnostic, also include the column number.
  #   
  #   This option corresponds to the clang flag \c -fshow-column.
  # :display_source_ranges ::
  #   If displaying the source-location information of the
  #   diagnostic, also include information about source ranges in a
  #   machine-parsable format.
  #   
  #   This option corresponds to the clang flag
  #   \c -fdiagnostics-print-source-range-info.
  # :display_option ::
  #   Display the option name associated with this diagnostic, if any.
  #   
  #   The option name displayed (e.g., -Wconversion) will be placed in brackets
  #   after the diagnostic text. This option corresponds to the clang flag
  #   \c -fdiagnostics-show-option.
  # :display_category_id ::
  #   Display the category number associated with this diagnostic, if any.
  #   
  #   The category number is displayed within brackets after the diagnostic text.
  #   This option corresponds to the clang flag 
  #   \c -fdiagnostics-show-category=id.
  # :display_category_name ::
  #   Display the category name associated with this diagnostic, if any.
  #   
  #   The category name is displayed within brackets after the diagnostic text.
  #   This option corresponds to the clang flag 
  #   \c -fdiagnostics-show-category=name.
  # 
  # @method _enum_diagnostic_display_options_
  # @return [Symbol]
  # @scope class
  enum :diagnostic_display_options, [
    :display_source_location, 0x01,
    :display_column, 0x02,
    :display_source_ranges, 0x04,
    :display_option, 0x08,
    :display_category_id, 0x10,
    :display_category_name, 0x20
  ]
  
  # Format the given diagnostic in a manner that is suitable for display.
  # 
  # This routine will format the given diagnostic to a string, rendering
  # the diagnostic according to the various options given. The
  # \c clang_defaultDiagnosticDisplayOptions() function returns the set of
  # options that most closely mimics the behavior of the clang compiler.
  # 
  # @method format_diagnostic(diagnostic, options)
  # @param [FFI::Pointer(Diagnostic)] diagnostic The diagnostic to print.
  # @param [Integer] options A set of options that control the diagnostic display,
  #   created by combining \c CXDiagnosticDisplayOptions values.
  # @return [String] A new string containing for formatted diagnostic.
  # @scope class
  attach_function :format_diagnostic, :clang_formatDiagnostic, [:pointer, :uint], String.by_value
  
  # Retrieve the set of display options most similar to the
  # default behavior of the clang compiler.
  # 
  # @method default_diagnostic_display_options()
  # @return [Integer] A set of display options suitable for use with \c
  #   clang_displayDiagnostic().
  # @scope class
  attach_function :default_diagnostic_display_options, :clang_defaultDiagnosticDisplayOptions, [], :uint
  
  # Determine the severity of the given diagnostic.
  # 
  # @method get_diagnostic_severity(diagnostic)
  # @param [FFI::Pointer(Diagnostic)] diagnostic 
  # @return [Symbol from _enum_diagnostic_severity_] 
  # @scope class
  attach_function :get_diagnostic_severity, :clang_getDiagnosticSeverity, [:pointer], :diagnostic_severity
  
  # Retrieve the source location of the given diagnostic.
  # 
  # This location is where Clang would print the caret ('^') when
  # displaying the diagnostic on the command line.
  # 
  # @method get_diagnostic_location(diagnostic)
  # @param [FFI::Pointer(Diagnostic)] diagnostic 
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_diagnostic_location, :clang_getDiagnosticLocation, [:pointer], SourceLocation.by_value
  
  # Retrieve the text of the given diagnostic.
  # 
  # @method get_diagnostic_spelling(diagnostic)
  # @param [FFI::Pointer(Diagnostic)] diagnostic 
  # @return [String] 
  # @scope class
  attach_function :get_diagnostic_spelling, :clang_getDiagnosticSpelling, [:pointer], String.by_value
  
  # Retrieve the name of the command-line option that enabled this
  # diagnostic.
  # 
  # @method get_diagnostic_option(diag, disable)
  # @param [FFI::Pointer(Diagnostic)] diag The diagnostic to be queried.
  # @param [String] disable If non-NULL, will be set to the option that disables this
  #   diagnostic (if any).
  # @return [String] A string that contains the command-line option used to enable this
  #   warning, such as "-Wconversion" or "-pedantic". 
  # @scope class
  attach_function :get_diagnostic_option, :clang_getDiagnosticOption, [:pointer, String], String.by_value
  
  # Retrieve the category number for this diagnostic.
  # 
  # Diagnostics can be categorized into groups along with other, related
  # diagnostics (e.g., diagnostics under the same warning flag). This routine 
  # retrieves the category number for the given diagnostic.
  # 
  # @method get_diagnostic_category(diagnostic)
  # @param [FFI::Pointer(Diagnostic)] diagnostic 
  # @return [Integer] The number of the category that contains this diagnostic, or zero
  #   if this diagnostic is uncategorized.
  # @scope class
  attach_function :get_diagnostic_category, :clang_getDiagnosticCategory, [:pointer], :uint
  
  # Retrieve the name of a particular diagnostic category.
  # 
  # @method get_diagnostic_category_name(category)
  # @param [Integer] category A diagnostic category number, as returned by 
  #   \c clang_getDiagnosticCategory().
  # @return [String] The name of the given diagnostic category.
  # @scope class
  attach_function :get_diagnostic_category_name, :clang_getDiagnosticCategoryName, [:uint], String.by_value
  
  # Determine the number of source ranges associated with the given
  # diagnostic.
  # 
  # @method get_diagnostic_num_ranges(diagnostic)
  # @param [FFI::Pointer(Diagnostic)] diagnostic 
  # @return [Integer] 
  # @scope class
  attach_function :get_diagnostic_num_ranges, :clang_getDiagnosticNumRanges, [:pointer], :uint
  
  # Retrieve a source range associated with the diagnostic.
  # 
  # A diagnostic's source ranges highlight important elements in the source
  # code. On the command line, Clang displays source ranges by
  # underlining them with '~' characters.
  # 
  # @method get_diagnostic_range(diagnostic, range)
  # @param [FFI::Pointer(Diagnostic)] diagnostic the diagnostic whose range is being extracted.
  # @param [Integer] range the zero-based index specifying which range to
  # @return [SourceRange] the requested source range.
  # @scope class
  attach_function :get_diagnostic_range, :clang_getDiagnosticRange, [:pointer, :uint], SourceRange.by_value
  
  # Determine the number of fix-it hints associated with the
  # given diagnostic.
  # 
  # @method get_diagnostic_num_fix_its(diagnostic)
  # @param [FFI::Pointer(Diagnostic)] diagnostic 
  # @return [Integer] 
  # @scope class
  attach_function :get_diagnostic_num_fix_its, :clang_getDiagnosticNumFixIts, [:pointer], :uint
  
  # Retrieve the replacement information for a given fix-it.
  # 
  # Fix-its are described in terms of a source range whose contents
  # should be replaced by a string. This approach generalizes over
  # three kinds of operations: removal of source code (the range covers
  # the code to be removed and the replacement string is empty),
  # replacement of source code (the range covers the code to be
  # replaced and the replacement string provides the new code), and
  # insertion (both the start and end of the range point at the
  # insertion location, and the replacement string provides the text to
  # insert).
  # 
  # @method get_diagnostic_fix_it(diagnostic, fix_it, replacement_range)
  # @param [FFI::Pointer(Diagnostic)] diagnostic The diagnostic whose fix-its are being queried.
  # @param [Integer] fix_it The zero-based index of the fix-it.
  # @param [SourceRange] replacement_range The source range whose contents will be
  #   replaced with the returned replacement string. Note that source
  #   ranges are half-open ranges (a, b), so the source code should be
  #   replaced from a and up to (but not including) b.
  # @return [String] A string containing text that should be replace the source
  #   code indicated by the \c ReplacementRange.
  # @scope class
  attach_function :get_diagnostic_fix_it, :clang_getDiagnosticFixIt, [:pointer, :uint, SourceRange], String.by_value
  
  # Get the original translation unit source file name.
  # 
  # @method get_translation_unit_spelling(ct_unit)
  # @param [TranslationUnitImpl] ct_unit 
  # @return [String] 
  # @scope class
  attach_function :get_translation_unit_spelling, :clang_getTranslationUnitSpelling, [TranslationUnitImpl], String.by_value
  
  # Return the CXTranslationUnit for a given source file and the provided
  # command line arguments one would pass to the compiler.
  # 
  # Note: The 'source_filename' argument is optional.  If the caller provides a
  # NULL pointer, the name of the source file is expected to reside in the
  # specified command line arguments.
  # 
  # Note: When encountered in 'clang_command_line_args', the following options
  # are ignored:
  # 
  #   '-c'
  #   '-emit-ast'
  #   '-fsyntax-only'
  #   '-o <output file>'  (both '-o' and '<output file>' are ignored)
  # 
  # @method create_translation_unit_from_source_file(c_idx, source_filename, num_clang_command_line_args, command_line_args, num_unsaved_files, unsaved_files)
  # @param [FFI::Pointer(Index)] c_idx The index object with which the translation unit will be
  #   associated.
  # @param [String] source_filename - The name of the source file to load, or NULL if the
  #   source file is included in \p clang_command_line_args.
  # @param [Integer] num_clang_command_line_args The number of command-line arguments in
  #   \p clang_command_line_args.
  # @param [FFI::Pointer(**Char_S)] command_line_args The command-line arguments that would be
  #   passed to the \c clang executable if it were being invoked out-of-process.
  #   These command-line options will be parsed and will affect how the translation
  #   unit is parsed. Note that the following options are ignored: '-c',
  #   '-emit-ast', '-fsyntex-only' (which is the default), and '-o <output file>'.
  # @param [Integer] num_unsaved_files the number of unsaved file entries in \p
  #   unsaved_files.
  # @param [UnsavedFile] unsaved_files the files that have not yet been saved to disk
  #   but may be required for code completion, including the contents of
  #   those files.  The contents and name of these files (as specified by
  #   CXUnsavedFile) are copied when necessary, so the client only needs to
  #   guarantee their validity until the call to this function returns.
  # @return [TranslationUnitImpl] 
  # @scope class
  attach_function :create_translation_unit_from_source_file, :clang_createTranslationUnitFromSourceFile, [:pointer, :string, :int, :pointer, :uint, UnsavedFile], TranslationUnitImpl
  
  # Create a translation unit from an AST file (-emit-ast).
  # 
  # @method create_translation_unit(index, ast_filename)
  # @param [FFI::Pointer(Index)] index 
  # @param [String] ast_filename 
  # @return [TranslationUnitImpl] 
  # @scope class
  attach_function :create_translation_unit, :clang_createTranslationUnit, [:pointer, :string], TranslationUnitImpl
  
  # Flags that control the creation of translation units.
  # 
  # The enumerators in this enumeration type are meant to be bitwise
  # ORed together to specify which options should be used when
  # constructing the translation unit.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:translation_unit_flags).</em>
  # 
  # === Options:
  # :none ::
  #   Used to indicate that no special translation-unit options are
  #   needed.
  # :detailed_preprocessing_record ::
  #   Used to indicate that the parser should construct a "detailed"
  #   preprocessing record, including all macro definitions and instantiations.
  #   
  #   Constructing a detailed preprocessing record requires more memory
  #   and time to parse, since the information contained in the record
  #   is usually not retained. However, it can be useful for
  #   applications that require more detailed information about the
  #   behavior of the preprocessor.
  # :incomplete ::
  #   Used to indicate that the translation unit is incomplete.
  #   
  #   When a translation unit is considered "incomplete", semantic
  #   analysis that is typically performed at the end of the
  #   translation unit will be suppressed. For example, this suppresses
  #   the completion of tentative declarations in C and of
  #   instantiation of implicitly-instantiation function templates in
  #   C++. This option is typically used when parsing a header with the
  #   intent of producing a precompiled header.
  # :precompiled_preamble ::
  #   Used to indicate that the translation unit should be built with an 
  #   implicit precompiled header for the preamble.
  #   
  #   An implicit precompiled header is used as an optimization when a
  #   particular translation unit is likely to be reparsed many times
  #   when the sources aren't changing that often. In this case, an
  #   implicit precompiled header will be built containing all of the
  #   initial includes at the top of the main file (what we refer to as
  #   the "preamble" of the file). In subsequent parses, if the
  #   preamble or the files in it have not changed, \c
  #   clang_reparseTranslationUnit() will re-use the implicit
  #   precompiled header to improve parsing performance.
  # :cache_completion_results ::
  #   Used to indicate that the translation unit should cache some
  #   code-completion results with each reparse of the source file.
  #   
  #   Caching of code-completion results is a performance optimization that
  #   introduces some overhead to reparsing but improves the performance of
  #   code-completion operations.
  # :x_precompiled_preamble ::
  #   DEPRECATED: Enable precompiled preambles in C++.
  #   
  #   Note: this is a *temporary* option that is available only while
  #   we are testing C++ precompiled preamble support. It is deprecated.
  # :x_chained_pch ::
  #   DEPRECATED: Enabled chained precompiled preambles in C++.
  #   
  #   Note: this is a *temporary* option that is available only while
  #   we are testing C++ precompiled preamble support. It is deprecated.
  # :nested_macro_expansions ::
  #   Used to indicate that the "detailed" preprocessing record,
  #   if requested, should also contain nested macro expansions.
  #   
  #   Nested macro expansions (i.e., macro expansions that occur
  #   inside another macro expansion) can, in some code bases, require
  #   a large amount of storage to due preprocessor metaprogramming. Moreover,
  #   its fairly rare that this information is useful for libclang clients.
  # 
  # @method _enum_translation_unit_flags_
  # @return [Symbol]
  # @scope class
  enum :translation_unit_flags, [
    :none, 0x0,
    :detailed_preprocessing_record, 0x01,
    :incomplete, 0x02,
    :precompiled_preamble, 0x04,
    :cache_completion_results, 0x08,
    :x_precompiled_preamble, 0x10,
    :x_chained_pch, 0x20,
    :nested_macro_expansions, 0x40
  ]
  
  # Returns the set of flags that is suitable for parsing a translation
  # unit that is being edited.
  # 
  # The set of flags returned provide options for \c clang_parseTranslationUnit()
  # to indicate that the translation unit is likely to be reparsed many times,
  # either explicitly (via \c clang_reparseTranslationUnit()) or implicitly
  # (e.g., by code completion (\c clang_codeCompletionAt())). The returned flag
  # set contains an unspecified set of optimizations (e.g., the precompiled 
  # preamble) geared toward improving the performance of these routines. The
  # set of optimizations enabled may change from one version to the next.
  # 
  # @method default_editing_translation_unit_options()
  # @return [Integer] 
  # @scope class
  attach_function :default_editing_translation_unit_options, :clang_defaultEditingTranslationUnitOptions, [], :uint
  
  # Parse the given source file and the translation unit corresponding
  # to that file.
  # 
  # This routine is the main entry point for the Clang C API, providing the
  # ability to parse a source file into a translation unit that can then be
  # queried by other functions in the API. This routine accepts a set of
  # command-line arguments so that the compilation can be configured in the same
  # way that the compiler is configured on the command line.
  # 
  # @method parse_translation_unit(c_idx, source_filename, command_line_args, num_command_line_args, unsaved_files, num_unsaved_files, options)
  # @param [FFI::Pointer(Index)] c_idx The index object with which the translation unit will be 
  #   associated.
  # @param [String] source_filename The name of the source file to load, or NULL if the
  #   source file is included in \p command_line_args.
  # @param [FFI::Pointer(**Char_S)] command_line_args The command-line arguments that would be
  #   passed to the \c clang executable if it were being invoked out-of-process.
  #   These command-line options will be parsed and will affect how the translation
  #   unit is parsed. Note that the following options are ignored: '-c', 
  #   '-emit-ast', '-fsyntex-only' (which is the default), and '-o <output file>'.
  # @param [Integer] num_command_line_args The number of command-line arguments in
  #   \p command_line_args.
  # @param [UnsavedFile] unsaved_files the files that have not yet been saved to disk
  #   but may be required for parsing, including the contents of
  #   those files.  The contents and name of these files (as specified by
  #   CXUnsavedFile) are copied when necessary, so the client only needs to
  #   guarantee their validity until the call to this function returns.
  # @param [Integer] num_unsaved_files the number of unsaved file entries in \p
  #   unsaved_files.
  # @param [Integer] options A bitmask of options that affects how the translation unit
  #   is managed but not its compilation. This should be a bitwise OR of the
  #   CXTranslationUnit_XXX flags.
  # @return [TranslationUnitImpl] A new translation unit describing the parsed code and containing
  #   any diagnostics produced by the compiler. If there is a failure from which
  #   the compiler cannot recover, returns NULL.
  # @scope class
  attach_function :parse_translation_unit, :clang_parseTranslationUnit, [:pointer, :string, :pointer, :int, UnsavedFile, :uint, :uint], TranslationUnitImpl
  
  # Flags that control how translation units are saved.
  # 
  # The enumerators in this enumeration type are meant to be bitwise
  # ORed together to specify which options should be used when
  # saving the translation unit.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:save_translation_unit_flags).</em>
  # 
  # === Options:
  # :save_translation_unit_none ::
  #   Used to indicate that no special saving options are needed.
  # 
  # @method _enum_save_translation_unit_flags_
  # @return [Symbol]
  # @scope class
  enum :save_translation_unit_flags, [
    :save_translation_unit_none, 0x0
  ]
  
  # Returns the set of flags that is suitable for saving a translation
  # unit.
  # 
  # The set of flags returned provide options for
  # \c clang_saveTranslationUnit() by default. The returned flag
  # set contains an unspecified set of options that save translation units with
  # the most commonly-requested data.
  # 
  # @method default_save_options(tu)
  # @param [TranslationUnitImpl] tu 
  # @return [Integer] 
  # @scope class
  attach_function :default_save_options, :clang_defaultSaveOptions, [TranslationUnitImpl], :uint
  
  # Describes the kind of error that occurred (if any) in a call to
  # \c clang_saveTranslationUnit().
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:save_error).</em>
  # 
  # === Options:
  # :none ::
  #   Indicates that no error occurred while saving a translation unit.
  # :unknown ::
  #   Indicates that an unknown error occurred while attempting to save
  #   the file.
  #   
  #   This error typically indicates that file I/O failed when attempting to 
  #   write the file.
  # :translation_errors ::
  #   Indicates that errors during translation prevented this attempt
  #   to save the translation unit.
  #   
  #   Errors that prevent the translation unit from being saved can be
  #   extracted using \c clang_getNumDiagnostics() and \c clang_getDiagnostic().
  # :invalid_tu ::
  #   Indicates that the translation unit to be saved was somehow
  #   invalid (e.g., NULL).
  # 
  # @method _enum_save_error_
  # @return [Symbol]
  # @scope class
  enum :save_error, [
    :none, 0,
    :unknown, 1,
    :translation_errors, 2,
    :invalid_tu, 3
  ]
  
  # Saves a translation unit into a serialized representation of
  # that translation unit on disk.
  # 
  # Any translation unit that was parsed without error can be saved
  # into a file. The translation unit can then be deserialized into a
  # new \c CXTranslationUnit with \c clang_createTranslationUnit() or,
  # if it is an incomplete translation unit that corresponds to a
  # header, used as a precompiled header when parsing other translation
  # units.
  # 
  # @method save_translation_unit(tu, file_name, options)
  # @param [TranslationUnitImpl] tu The translation unit to save.
  # @param [String] file_name The file to which the translation unit will be saved.
  # @param [Integer] options A bitmask of options that affects how the translation unit
  #   is saved. This should be a bitwise OR of the
  #   CXSaveTranslationUnit_XXX flags.
  # @return [Integer] A value that will match one of the enumerators of the CXSaveError
  #   enumeration. Zero (CXSaveError_None) indicates that the translation unit was 
  #   saved successfully, while a non-zero value indicates that a problem occurred.
  # @scope class
  attach_function :save_translation_unit, :clang_saveTranslationUnit, [TranslationUnitImpl, :string, :uint], :int
  
  # Destroy the specified CXTranslationUnit object.
  # 
  # @method dispose_translation_unit(translation_unit_impl)
  # @param [TranslationUnitImpl] translation_unit_impl 
  # @return [nil] 
  # @scope class
  attach_function :dispose_translation_unit, :clang_disposeTranslationUnit, [TranslationUnitImplStruct], :void
  
  # Flags that control the reparsing of translation units.
  # 
  # The enumerators in this enumeration type are meant to be bitwise
  # ORed together to specify which options should be used when
  # reparsing the translation unit.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:reparse_flags).</em>
  # 
  # === Options:
  # :reparse_none ::
  #   Used to indicate that no special reparsing options are needed.
  # 
  # @method _enum_reparse_flags_
  # @return [Symbol]
  # @scope class
  enum :reparse_flags, [
    :reparse_none, 0x0
  ]
  
  # Returns the set of flags that is suitable for reparsing a translation
  # unit.
  # 
  # The set of flags returned provide options for
  # \c clang_reparseTranslationUnit() by default. The returned flag
  # set contains an unspecified set of optimizations geared toward common uses
  # of reparsing. The set of optimizations enabled may change from one version 
  # to the next.
  # 
  # @method default_reparse_options(tu)
  # @param [TranslationUnitImpl] tu 
  # @return [Integer] 
  # @scope class
  attach_function :default_reparse_options, :clang_defaultReparseOptions, [TranslationUnitImpl], :uint
  
  # Reparse the source files that produced this translation unit.
  # 
  # This routine can be used to re-parse the source files that originally
  # created the given translation unit, for example because those source files
  # have changed (either on disk or as passed via \p unsaved_files). The
  # source code will be reparsed with the same command-line options as it
  # was originally parsed. 
  # 
  # Reparsing a translation unit invalidates all cursors and source locations
  # that refer into that translation unit. This makes reparsing a translation
  # unit semantically equivalent to destroying the translation unit and then
  # creating a new translation unit with the same command-line arguments.
  # However, it may be more efficient to reparse a translation 
  # unit using this routine.
  # 
  # @method reparse_translation_unit(tu, num_unsaved_files, unsaved_files, options)
  # @param [TranslationUnitImpl] tu The translation unit whose contents will be re-parsed. The
  #   translation unit must originally have been built with 
  #   \c clang_createTranslationUnitFromSourceFile().
  # @param [Integer] num_unsaved_files The number of unsaved file entries in \p
  #   unsaved_files.
  # @param [UnsavedFile] unsaved_files The files that have not yet been saved to disk
  #   but may be required for parsing, including the contents of
  #   those files.  The contents and name of these files (as specified by
  #   CXUnsavedFile) are copied when necessary, so the client only needs to
  #   guarantee their validity until the call to this function returns.
  # @param [Integer] options A bitset of options composed of the flags in CXReparse_Flags.
  #   The function \c clang_defaultReparseOptions() produces a default set of
  #   options recommended for most uses, based on the translation unit.
  # @return [Integer] 0 if the sources could be reparsed. A non-zero value will be
  #   returned if reparsing was impossible, such that the translation unit is
  #   invalid. In such cases, the only valid call for \p TU is 
  #   \c clang_disposeTranslationUnit(TU).
  # @scope class
  attach_function :reparse_translation_unit, :clang_reparseTranslationUnit, [TranslationUnitImpl, :uint, UnsavedFile, :uint], :int
  
  # Categorizes how memory is being used by a translation unit.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:tu_resource_usage_kind).</em>
  # 
  # === Options:
  # :ast ::
  #   
  # :identifiers ::
  #   
  # :selectors ::
  #   
  # :global_completion_results ::
  #   
  # :source_manager_content_cache ::
  #   
  # :ast_side_tables ::
  #   
  # :source_manager_membuffer_malloc ::
  #   
  # :source_manager_membuffer_m_map ::
  #   
  # :external_ast_source_membuffer_malloc ::
  #   
  # :external_ast_source_membuffer_m_map ::
  #   
  # :preprocessor ::
  #   
  # :preprocessing_record ::
  #   
  # :source_manager_data_structures ::
  #   
  # :preprocessor_header_search ::
  #   
  # 
  # @method _enum_tu_resource_usage_kind_
  # @return [Symbol]
  # @scope class
  enum :tu_resource_usage_kind, [
    :ast, 1,
    :identifiers, 2,
    :selectors, 3,
    :global_completion_results, 4,
    :source_manager_content_cache, 5,
    :ast_side_tables, 6,
    :source_manager_membuffer_malloc, 7,
    :source_manager_membuffer_m_map, 8,
    :external_ast_source_membuffer_malloc, 9,
    :external_ast_source_membuffer_m_map, 10,
    :preprocessor, 11,
    :preprocessing_record, 12,
    :source_manager_data_structures, 13,
    :preprocessor_header_search, 14
  ]
  
  # Returns the human-readable null-terminated C string that represents
  #  the name of the memory category.  This string should never be freed.
  # 
  # @method get_tu_resource_usage_name(kind)
  # @param [Symbol from _enum_tu_resource_usage_kind_] kind 
  # @return [String] 
  # @scope class
  attach_function :get_tu_resource_usage_name, :clang_getTUResourceUsageName, [:tu_resource_usage_kind], :string
  
  # (Not documented)
  # 
  # = Fields:
  # :kind ::
  #   (Symbol from _enum_tu_resource_usage_kind_) The memory usage category.
  # :amount ::
  #   (Integer) Amount of resources used. 
  #         The units will depend on the resource kind.
  class TUResourceUsageEntry < FFI::Struct
    layout :kind, :tu_resource_usage_kind,
           :amount, :ulong
  end
  
  # The memory usage of a CXTranslationUnit, broken into categories.
  # 
  # = Fields:
  # :data ::
  #   (FFI::Pointer(*Void)) Private data member, used for queries.
  # :num_entries ::
  #   (Integer) The number of entries in the 'entries' array.
  # :entries ::
  #   (TUResourceUsageEntry) An array of key-value pairs, representing the breakdown of memory
  #               usage.
  class TUResourceUsage < FFI::Struct
    layout :data, :pointer,
           :num_entries, :uint,
           :entries, TUResourceUsageEntry
  end
  
  # Return the memory usage of a translation unit.  This object
  #  should be released with clang_disposeCXTUResourceUsage().
  # 
  # @method get_cxtu_resource_usage(tu)
  # @param [TranslationUnitImpl] tu 
  # @return [TUResourceUsage] 
  # @scope class
  attach_function :get_cxtu_resource_usage, :clang_getCXTUResourceUsage, [TranslationUnitImpl], TUResourceUsage.by_value
  
  # (Not documented)
  # 
  # @method dispose_cxtu_resource_usage(usage)
  # @param [TUResourceUsage] usage 
  # @return [nil] 
  # @scope class
  attach_function :dispose_cxtu_resource_usage, :clang_disposeCXTUResourceUsage, [TUResourceUsage.by_value], :void
  
  # Describes the kind of entity that a cursor refers to.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:cursor_kind).</em>
  # 
  # === Options:
  # :unexposed_decl ::
  #   A declaration whose specific kind is not exposed via this
  #   interface.
  #   
  #   Unexposed declarations have the same operations as any other kind
  #   of declaration; one can extract their location information,
  #   spelling, find their definitions, etc. However, the specific kind
  #   of the declaration is not reported.
  # :struct_decl ::
  #   A C or C++ struct.
  # :union_decl ::
  #   A C or C++ union.
  # :class_decl ::
  #   A C++ class.
  # :enum_decl ::
  #   An enumeration.
  # :field_decl ::
  #   A field (in C) or non-static data member (in C++) in a
  #   struct, union, or C++ class.
  # :enum_constant_decl ::
  #   An enumerator constant.
  # :function_decl ::
  #   A function.
  # :var_decl ::
  #   A variable.
  # :parm_decl ::
  #   A function or method parameter.
  # :obj_c_interface_decl ::
  #   An Objective-C @interface.
  # :obj_c_category_decl ::
  #   An Objective-C @interface for a category.
  # :obj_c_protocol_decl ::
  #   An Objective-C @protocol declaration.
  # :obj_c_property_decl ::
  #   An Objective-C @property declaration.
  # :obj_c_ivar_decl ::
  #   An Objective-C instance variable.
  # :obj_c_instance_method_decl ::
  #   An Objective-C instance method.
  # :obj_c_class_method_decl ::
  #   An Objective-C class method.
  # :obj_c_implementation_decl ::
  #   An Objective-C @implementation.
  # :obj_c_category_impl_decl ::
  #   An Objective-C @implementation for a category.
  # :typedef_decl ::
  #   A typedef
  # :x_method ::
  #   A C++ class method.
  # :namespace ::
  #   A C++ namespace.
  # :linkage_spec ::
  #   A linkage specification, e.g. 'extern "C"'.
  # :constructor ::
  #   A C++ constructor.
  # :destructor ::
  #   A C++ destructor.
  # :conversion_function ::
  #   A C++ conversion function.
  # :template_type_parameter ::
  #   A C++ template type parameter.
  # :non_type_template_parameter ::
  #   A C++ non-type template parameter.
  # :template_template_parameter ::
  #   A C++ template template parameter.
  # :function_template ::
  #   A C++ function template.
  # :class_template ::
  #   A C++ class template.
  # :class_template_partial_specialization ::
  #   A C++ class template partial specialization.
  # :namespace_alias ::
  #   A C++ namespace alias declaration.
  # :using_directive ::
  #   A C++ using directive.
  # :using_declaration ::
  #   A C++ using declaration.
  # :type_alias_decl ::
  #   A C++ alias declaration
  # :obj_c_synthesize_decl ::
  #   An Objective-C @synthesize definition.
  # :obj_c_dynamic_decl ::
  #   An Objective-C @dynamic definition.
  # :x_access_specifier ::
  #   An access specifier.
  # :first_ref ::
  #   References
  # :obj_c_super_class_ref ::
  #   Decl references
  # :obj_c_protocol_ref ::
  #   
  # :obj_c_class_ref ::
  #   
  # :type_ref ::
  #   A reference to a type declaration.
  #   
  #   A type reference occurs anywhere where a type is named but not
  #   declared. For example, given:
  #   
  #   \code
  #   typedef unsigned size_type;
  #   size_type size;
  #   \endcode
  #   
  #   The typedef is a declaration of size_type (CXCursor_TypedefDecl),
  #   while the type of the variable "size" is referenced. The cursor
  #   referenced by the type of size is the typedef for size_type.
  # :x_base_specifier ::
  #   
  # :template_ref ::
  #   A reference to a class template, function template, template
  #   template parameter, or class template partial specialization.
  # :namespace_ref ::
  #   A reference to a namespace or namespace alias.
  # :member_ref ::
  #   A reference to a member of a struct, union, or class that occurs in 
  #   some non-expression context, e.g., a designated initializer.
  # :label_ref ::
  #   A reference to a labeled statement.
  #   
  #   This cursor kind is used to describe the jump to "start_over" in the 
  #   goto statement in the following example:
  #   
  #   \code
  #     start_over:
  #       ++counter;
  #   
  #       goto start_over;
  #   \endcode
  #   
  #   A label reference cursor refers to a label statement.
  # :overloaded_decl_ref ::
  #   A reference to a set of overloaded functions or function templates
  #   that has not yet been resolved to a specific function or function template.
  #   
  #   An overloaded declaration reference cursor occurs in C++ templates where
  #   a dependent name refers to a function. For example:
  #   
  #   \code
  #   template<typename T> void swap(T&, T&);
  #   
  #   struct X { ... };
  #   void swap(X&, X&);
  #   
  #   template<typename T>
  #   void reverse(T* first, T* last) {
  #     while (first < last - 1) {
  #       swap(*first, *--last);
  #       ++first;
  #     }
  #   }
  #   
  #   struct Y { };
  #   void swap(Y&, Y&);
  #   \endcode
  #   
  #   Here, the identifier "swap" is associated with an overloaded declaration
  #   reference. In the template definition, "swap" refers to either of the two
  #   "swap" functions declared above, so both results will be available. At
  #   instantiation time, "swap" may also refer to other functions found via
  #   argument-dependent lookup (e.g., the "swap" function at the end of the
  #   example).
  #   
  #   The functions \c clang_getNumOverloadedDecls() and 
  #   \c clang_getOverloadedDecl() can be used to retrieve the definitions
  #   referenced by this cursor.
  # :first_invalid ::
  #   Error conditions
  # :invalid_file ::
  #   
  # :no_decl_found ::
  #   
  # :not_implemented ::
  #   
  # :invalid_code ::
  #   
  # :first_expr ::
  #   Expressions
  # :unexposed_expr ::
  #   An expression whose specific kind is not exposed via this
  #   interface.
  #   
  #   Unexposed expressions have the same operations as any other kind
  #   of expression; one can extract their location information,
  #   spelling, children, etc. However, the specific kind of the
  #   expression is not reported.
  # :decl_ref_expr ::
  #   An expression that refers to some value declaration, such
  #   as a function, varible, or enumerator.
  # :member_ref_expr ::
  #   An expression that refers to a member of a struct, union,
  #   class, Objective-C class, etc.
  # :call_expr ::
  #   An expression that calls a function.
  # :obj_c_message_expr ::
  #   An expression that sends a message to an Objective-C
  #      object or class.
  # :block_expr ::
  #   An expression that represents a block literal.
  # :integer_literal ::
  #   An integer literal.
  # :floating_literal ::
  #   A floating point number literal.
  # :imaginary_literal ::
  #   An imaginary number literal.
  # :string_literal ::
  #   A string literal.
  # :character_literal ::
  #   A character literal.
  # :paren_expr ::
  #   A parenthesized expression, e.g. "(1)".
  #   
  #   This AST node is only formed if full location information is requested.
  # :unary_operator ::
  #   This represents the unary-expression's (except sizeof and
  #   alignof).
  # :array_subscript_expr ::
  #   (C99 6.5.2.1) Array Subscripting.
  # :binary_operator ::
  #   A builtin binary operation expression such as "x + y" or
  #   "x <= y".
  # :compound_assign_operator ::
  #   Compound assignment such as "+=".
  # :conditional_operator ::
  #   The ?: ternary operator.
  # :c_style_cast_expr ::
  #   An explicit cast in C (C99 6.5.4) or a C-style cast in C++
  #   (C++ (expr.cast)), which uses the syntax (Type)expr.
  #   
  #   For example: (int)f.
  # :compound_literal_expr ::
  #   (C99 6.5.2.5)
  # :init_list_expr ::
  #   Describes an C or C++ initializer list.
  # :addr_label_expr ::
  #   The GNU address of label extension, representing &&label.
  # :stmt_expr ::
  #   This is the GNU Statement Expression extension: ({int X=4; X;})
  # :generic_selection_expr ::
  #   Represents a C1X generic selection.
  # :gnu_null_expr ::
  #   Implements the GNU __null extension, which is a name for a null
  #   pointer constant that has integral type (e.g., int or long) and is the same
  #   size and alignment as a pointer.
  #   
  #   The __null extension is typically only used by system headers, which define
  #   NULL as __null in C++ rather than using 0 (which is an integer that may not
  #   match the size of a pointer).
  # :x_static_cast_expr ::
  #   C++'s static_cast<> expression.
  # :x_dynamic_cast_expr ::
  #   C++'s dynamic_cast<> expression.
  # :x_reinterpret_cast_expr ::
  #   C++'s reinterpret_cast<> expression.
  # :x_const_cast_expr ::
  #   C++'s const_cast<> expression.
  # :x_functional_cast_expr ::
  #   Represents an explicit C++ type conversion that uses "functional"
  #   notion (C++ (expr.type.conv)).
  #   
  #   Example:
  #   \code
  #     x = int(0.5);
  #   \endcode
  # :x_typeid_expr ::
  #   A C++ typeid expression (C++ (expr.typeid)).
  # :x_bool_literal_expr ::
  #   (C++ 2.13.5) C++ Boolean Literal.
  # :x_null_ptr_literal_expr ::
  #   (C++0x 2.14.7) C++ Pointer Literal.
  # :x_this_expr ::
  #   Represents the "this" expression in C++
  # :x_throw_expr ::
  #   (C++ 15) C++ Throw Expression.
  #   
  #   This handles 'throw' and 'throw' assignment-expression. When
  #   assignment-expression isn't present, Op will be null.
  # :x_new_expr ::
  #   A new expression for memory allocation and constructor calls, e.g:
  #   "new CXXNewExpr(foo)".
  # :x_delete_expr ::
  #   A delete expression for memory deallocation and destructor calls,
  #   e.g. "delete() pArray".
  # :unary_expr ::
  #   A unary expression.
  # :obj_c_string_literal ::
  #   ObjCStringLiteral, used for Objective-C string literals i.e. "foo".
  # :obj_c_encode_expr ::
  #   ObjCEncodeExpr, used for in Objective-C.
  # :obj_c_selector_expr ::
  #   ObjCSelectorExpr used for in Objective-C.
  # :obj_c_protocol_expr ::
  #   Objective-C's protocol expression.
  # :obj_c_bridged_cast_expr ::
  #   An Objective-C "bridged" cast expression, which casts between
  #   Objective-C pointers and C pointers, transferring ownership in the process.
  #   
  #   \code
  #     NSString *str = (__bridge_transfer NSString *)CFCreateString();
  #   \endcode
  # :pack_expansion_expr ::
  #   Represents a C++0x pack expansion that produces a sequence of
  #   expressions.
  #   
  #   A pack expansion expression contains a pattern (which itself is an
  #   expression) followed by an ellipsis. For example:
  #   
  #   \code
  #   template<typename F, typename ...Types>
  #   void forward(F f, Types &&...args) {
  #    f(static_cast<Types&&>(args)...);
  #   }
  #   \endcode
  # :size_of_pack_expr ::
  #   Represents an expression that computes the length of a parameter
  #   pack.
  #   
  #   \code
  #   template<typename ...Types>
  #   struct count {
  #     static const unsigned value = sizeof...(Types);
  #   };
  #   \endcode
  # :first_stmt ::
  #   Statements
  # :unexposed_stmt ::
  #   A statement whose specific kind is not exposed via this
  #   interface.
  #   
  #   Unexposed statements have the same operations as any other kind of
  #   statement; one can extract their location information, spelling,
  #   children, etc. However, the specific kind of the statement is not
  #   reported.
  # :label_stmt ::
  #   A labelled statement in a function. 
  #   
  #   This cursor kind is used to describe the "start_over:" label statement in 
  #   the following example:
  #   
  #   \code
  #     start_over:
  #       ++counter;
  #   \endcode
  # :compound_stmt ::
  #   A group of statements like { stmt stmt }.
  #   
  #   This cursor kind is used to describe compound statements, e.g. function
  #   bodies.
  # :case_stmt ::
  #   A case statment.
  # :default_stmt ::
  #   A default statement.
  # :if_stmt ::
  #   An if statement
  # :switch_stmt ::
  #   A switch statement.
  # :while_stmt ::
  #   A while statement.
  # :do_stmt ::
  #   A do statement.
  # :for_stmt ::
  #   A for statement.
  # :goto_stmt ::
  #   A goto statement.
  # :indirect_goto_stmt ::
  #   An indirect goto statement.
  # :continue_stmt ::
  #   A continue statement.
  # :break_stmt ::
  #   A break statement.
  # :return_stmt ::
  #   A return statement.
  # :asm_stmt ::
  #   A GNU inline assembly statement extension.
  # :obj_c_at_try_stmt ::
  #   Objective-C's overall @try-@catc-@finall statement.
  # :obj_c_at_catch_stmt ::
  #   Objective-C's @catch statement.
  # :obj_c_at_finally_stmt ::
  #   Objective-C's @finally statement.
  # :obj_c_at_throw_stmt ::
  #   Objective-C's @throw statement.
  # :obj_c_at_synchronized_stmt ::
  #   Objective-C's @synchronized statement.
  # :obj_c_autorelease_pool_stmt ::
  #   Objective-C's autorelease pool statement.
  # :obj_c_for_collection_stmt ::
  #   Objective-C's collection statement.
  # :x_catch_stmt ::
  #   C++'s catch statement.
  # :x_try_stmt ::
  #   C++'s try statement.
  # :x_for_range_stmt ::
  #   C++'s for (* : *) statement.
  # :seh_try_stmt ::
  #   Windows Structured Exception Handling's try statement.
  # :seh_except_stmt ::
  #   Windows Structured Exception Handling's except statement.
  # :seh_finally_stmt ::
  #   Windows Structured Exception Handling's finally statement.
  # :null_stmt ::
  #   The null satement ";": C99 6.8.3p3.
  #   
  #   This cursor kind is used to describe the null statement.
  # :decl_stmt ::
  #   Adaptor class for mixing declarations with statements and
  #   expressions.
  # :translation_unit ::
  #   Cursor that represents the translation unit itself.
  #   
  #   The translation unit cursor exists primarily to act as the root
  #   cursor for traversing the contents of a translation unit.
  # :first_attr ::
  #   Attributes
  # :unexposed_attr ::
  #   An attribute whose specific kind is not exposed via this
  #   interface.
  # :ib_action_attr ::
  #   
  # :ib_outlet_attr ::
  #   
  # :ib_outlet_collection_attr ::
  #   
  # :x_final_attr ::
  #   
  # :x_override_attr ::
  #   
  # :annotate_attr ::
  #   
  # :preprocessing_directive ::
  #   Preprocessing
  # :macro_definition ::
  #   
  # :macro_expansion ::
  #   
  # :inclusion_directive ::
  #   
  # 
  # @method _enum_cursor_kind_
  # @return [Symbol]
  # @scope class
  enum :cursor_kind, [
    :unexposed_decl, 1,
    :struct_decl, 2,
    :union_decl, 3,
    :class_decl, 4,
    :enum_decl, 5,
    :field_decl, 6,
    :enum_constant_decl, 7,
    :function_decl, 8,
    :var_decl, 9,
    :parm_decl, 10,
    :obj_c_interface_decl, 11,
    :obj_c_category_decl, 12,
    :obj_c_protocol_decl, 13,
    :obj_c_property_decl, 14,
    :obj_c_ivar_decl, 15,
    :obj_c_instance_method_decl, 16,
    :obj_c_class_method_decl, 17,
    :obj_c_implementation_decl, 18,
    :obj_c_category_impl_decl, 19,
    :typedef_decl, 20,
    :x_method, 21,
    :namespace, 22,
    :linkage_spec, 23,
    :constructor, 24,
    :destructor, 25,
    :conversion_function, 26,
    :template_type_parameter, 27,
    :non_type_template_parameter, 28,
    :template_template_parameter, 29,
    :function_template, 30,
    :class_template, 31,
    :class_template_partial_specialization, 32,
    :namespace_alias, 33,
    :using_directive, 34,
    :using_declaration, 35,
    :type_alias_decl, 36,
    :obj_c_synthesize_decl, 37,
    :obj_c_dynamic_decl, 38,
    :x_access_specifier, 39,
    :first_ref, 40,
    :obj_c_super_class_ref, 40,
    :obj_c_protocol_ref, 41,
    :obj_c_class_ref, 42,
    :type_ref, 43,
    :x_base_specifier, 44,
    :template_ref, 45,
    :namespace_ref, 46,
    :member_ref, 47,
    :label_ref, 48,
    :overloaded_decl_ref, 49,
    :first_invalid, 70,
    :invalid_file, 70,
    :no_decl_found, 71,
    :not_implemented, 72,
    :invalid_code, 73,
    :first_expr, 100,
    :unexposed_expr, 100,
    :decl_ref_expr, 101,
    :member_ref_expr, 102,
    :call_expr, 103,
    :obj_c_message_expr, 104,
    :block_expr, 105,
    :integer_literal, 106,
    :floating_literal, 107,
    :imaginary_literal, 108,
    :string_literal, 109,
    :character_literal, 110,
    :paren_expr, 111,
    :unary_operator, 112,
    :array_subscript_expr, 113,
    :binary_operator, 114,
    :compound_assign_operator, 115,
    :conditional_operator, 116,
    :c_style_cast_expr, 117,
    :compound_literal_expr, 118,
    :init_list_expr, 119,
    :addr_label_expr, 120,
    :stmt_expr, 121,
    :generic_selection_expr, 122,
    :gnu_null_expr, 123,
    :x_static_cast_expr, 124,
    :x_dynamic_cast_expr, 125,
    :x_reinterpret_cast_expr, 126,
    :x_const_cast_expr, 127,
    :x_functional_cast_expr, 128,
    :x_typeid_expr, 129,
    :x_bool_literal_expr, 130,
    :x_null_ptr_literal_expr, 131,
    :x_this_expr, 132,
    :x_throw_expr, 133,
    :x_new_expr, 134,
    :x_delete_expr, 135,
    :unary_expr, 136,
    :obj_c_string_literal, 137,
    :obj_c_encode_expr, 138,
    :obj_c_selector_expr, 139,
    :obj_c_protocol_expr, 140,
    :obj_c_bridged_cast_expr, 141,
    :pack_expansion_expr, 142,
    :size_of_pack_expr, 143,
    :first_stmt, 200,
    :unexposed_stmt, 200,
    :label_stmt, 201,
    :compound_stmt, 202,
    :case_stmt, 203,
    :default_stmt, 204,
    :if_stmt, 205,
    :switch_stmt, 206,
    :while_stmt, 207,
    :do_stmt, 208,
    :for_stmt, 209,
    :goto_stmt, 210,
    :indirect_goto_stmt, 211,
    :continue_stmt, 212,
    :break_stmt, 213,
    :return_stmt, 214,
    :asm_stmt, 215,
    :obj_c_at_try_stmt, 216,
    :obj_c_at_catch_stmt, 217,
    :obj_c_at_finally_stmt, 218,
    :obj_c_at_throw_stmt, 219,
    :obj_c_at_synchronized_stmt, 220,
    :obj_c_autorelease_pool_stmt, 221,
    :obj_c_for_collection_stmt, 222,
    :x_catch_stmt, 223,
    :x_try_stmt, 224,
    :x_for_range_stmt, 225,
    :seh_try_stmt, 226,
    :seh_except_stmt, 227,
    :seh_finally_stmt, 228,
    :null_stmt, 230,
    :decl_stmt, 231,
    :translation_unit, 300,
    :first_attr, 400,
    :unexposed_attr, 400,
    :ib_action_attr, 401,
    :ib_outlet_attr, 402,
    :ib_outlet_collection_attr, 403,
    :x_final_attr, 404,
    :x_override_attr, 405,
    :annotate_attr, 406,
    :preprocessing_directive, 500,
    :macro_definition, 501,
    :macro_expansion, 502,
    :inclusion_directive, 503
  ]
  
  # Retrieve the NULL cursor, which represents no entity.
  # 
  # @method get_null_cursor()
  # @return [Cursor] 
  # @scope class
  attach_function :get_null_cursor, :clang_getNullCursor, [], Cursor.by_value
  
  # Retrieve the cursor that represents the given translation unit.
  # 
  # The translation unit cursor can be used to start traversing the
  # various declarations within the given translation unit.
  # 
  # @method get_translation_unit_cursor(translation_unit_impl)
  # @param [TranslationUnitImpl] translation_unit_impl 
  # @return [Cursor] 
  # @scope class
  attach_function :get_translation_unit_cursor, :clang_getTranslationUnitCursor, [TranslationUnitImpl], Cursor.by_value
  
  # Determine whether two cursors are equivalent.
  # 
  # @method equal_cursors(cursor, cursor)
  # @param [Cursor] cursor 
  # @param [Cursor] cursor 
  # @return [Integer] 
  # @scope class
  attach_function :equal_cursors, :clang_equalCursors, [Cursor.by_value, Cursor.by_value], :uint
  
  # Returns non-zero if \arg cursor is null.
  # 
  # @method cursor_is_null(cursor)
  # @param [Cursor] cursor 
  # @return [Integer] 
  # @scope class
  attach_function :cursor_is_null, :clang_Cursor_isNull, [Cursor.by_value], :int
  
  # Compute a hash value for the given cursor.
  # 
  # @method hash_cursor(cursor)
  # @param [Cursor] cursor 
  # @return [Integer] 
  # @scope class
  attach_function :hash_cursor, :clang_hashCursor, [Cursor.by_value], :uint
  
  # Retrieve the kind of the given cursor.
  # 
  # @method get_cursor_kind(cursor)
  # @param [Cursor] cursor 
  # @return [Symbol from _enum_cursor_kind_] 
  # @scope class
  attach_function :get_cursor_kind, :clang_getCursorKind, [Cursor.by_value], :cursor_kind
  
  # Determine whether the given cursor kind represents a declaration.
  # 
  # @method is_declaration(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_declaration, :clang_isDeclaration, [:cursor_kind], :uint
  
  # Determine whether the given cursor kind represents a simple
  # reference.
  # 
  # Note that other kinds of cursors (such as expressions) can also refer to
  # other cursors. Use clang_getCursorReferenced() to determine whether a
  # particular cursor refers to another entity.
  # 
  # @method is_reference(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_reference, :clang_isReference, [:cursor_kind], :uint
  
  # Determine whether the given cursor kind represents an expression.
  # 
  # @method is_expression(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_expression, :clang_isExpression, [:cursor_kind], :uint
  
  # Determine whether the given cursor kind represents a statement.
  # 
  # @method is_statement(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_statement, :clang_isStatement, [:cursor_kind], :uint
  
  # Determine whether the given cursor kind represents an attribute.
  # 
  # @method is_attribute(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_attribute, :clang_isAttribute, [:cursor_kind], :uint
  
  # Determine whether the given cursor kind represents an invalid
  # cursor.
  # 
  # @method is_invalid(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_invalid, :clang_isInvalid, [:cursor_kind], :uint
  
  # Determine whether the given cursor kind represents a translation
  # unit.
  # 
  # @method is_translation_unit(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_translation_unit, :clang_isTranslationUnit, [:cursor_kind], :uint
  
  # Determine whether the given cursor represents a preprocessing
  # element, such as a preprocessor directive or macro instantiation.
  # 
  # @method is_preprocessing(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_preprocessing, :clang_isPreprocessing, [:cursor_kind], :uint
  
  # Determine whether the given cursor represents a currently
  #  unexposed piece of the AST (e.g., CXCursor_UnexposedStmt).
  # 
  # @method is_unexposed(cursor_kind)
  # @param [Symbol from _enum_cursor_kind_] cursor_kind 
  # @return [Integer] 
  # @scope class
  attach_function :is_unexposed, :clang_isUnexposed, [:cursor_kind], :uint
  
  # Describe the linkage of the entity referred to by a cursor.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:linkage_kind).</em>
  # 
  # === Options:
  # :invalid ::
  #   This value indicates that no linkage information is available
  #   for a provided CXCursor.
  # :no_linkage ::
  #   This is the linkage for variables, parameters, and so on that
  #    have automatic storage.  This covers normal (non-extern) local variables.
  # :internal ::
  #   This is the linkage for static variables and static functions.
  # :unique_external ::
  #   This is the linkage for entities with external linkage that live
  #   in C++ anonymous namespaces.
  # :external ::
  #   This is the linkage for entities with true, external linkage.
  # 
  # @method _enum_linkage_kind_
  # @return [Symbol]
  # @scope class
  enum :linkage_kind, [
    :invalid,
    :no_linkage,
    :internal,
    :unique_external,
    :external
  ]
  
  # Determine the linkage of the entity referred to by a given cursor.
  # 
  # @method get_cursor_linkage(cursor)
  # @param [Cursor] cursor 
  # @return [Symbol from _enum_linkage_kind_] 
  # @scope class
  attach_function :get_cursor_linkage, :clang_getCursorLinkage, [Cursor.by_value], :linkage_kind
  
  # Determine the availability of the entity that this cursor refers to.
  # 
  # @method get_cursor_availability(cursor)
  # @param [Cursor] cursor The cursor to query.
  # @return [Symbol from _enum_availability_kind_] The availability of the cursor.
  # @scope class
  attach_function :get_cursor_availability, :clang_getCursorAvailability, [Cursor.by_value], :availability_kind
  
  # Describe the "language" of the entity referred to by a cursor.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:language_kind).</em>
  # 
  # === Options:
  # :invalid ::
  #   
  # :c ::
  #   
  # :obj_c ::
  #   
  # :c_plus_plus ::
  #   
  # 
  # @method _enum_language_kind_
  # @return [Symbol]
  # @scope class
  enum :language_kind, [
    :invalid, 0,
    :c,
    :obj_c,
    :c_plus_plus
  ]
  
  # Determine the "language" of the entity referred to by a given cursor.
  # 
  # @method get_cursor_language(cursor)
  # @param [Cursor] cursor 
  # @return [Symbol from _enum_language_kind_] 
  # @scope class
  attach_function :get_cursor_language, :clang_getCursorLanguage, [Cursor.by_value], :language_kind
  
  # Returns the translation unit that a cursor originated from.
  # 
  # @method cursor_get_translation_unit(cursor)
  # @param [Cursor] cursor 
  # @return [TranslationUnitImpl] 
  # @scope class
  attach_function :cursor_get_translation_unit, :clang_Cursor_getTranslationUnit, [Cursor.by_value], TranslationUnitImpl
  
  # A fast container representing a set of CXCursors.
  class CursorSetImpl < FFI::Struct
    layout :dummy, :char
  end
  
  # Creates an empty CXCursorSet.
  # 
  # @method create_cx_cursor_set()
  # @return [CursorSetImpl] 
  # @scope class
  attach_function :create_cx_cursor_set, :clang_createCXCursorSet, [], CursorSetImpl
  
  # Disposes a CXCursorSet and releases its associated memory.
  # 
  # @method dispose_cx_cursor_set(cset)
  # @param [CursorSetImpl] cset 
  # @return [nil] 
  # @scope class
  attach_function :dispose_cx_cursor_set, :clang_disposeCXCursorSet, [CursorSetImpl], :void
  
  # Queries a CXCursorSet to see if it contains a specific CXCursor.
  # 
  # @method cx_cursor_set_contains(cset, cursor)
  # @param [CursorSetImpl] cset 
  # @param [Cursor] cursor 
  # @return [Integer] non-zero if the set contains the specified cursor.
  # @scope class
  attach_function :cx_cursor_set_contains, :clang_CXCursorSet_contains, [CursorSetImpl, Cursor.by_value], :uint
  
  # Inserts a CXCursor into a CXCursorSet.
  # 
  # @method cx_cursor_set_insert(cset, cursor)
  # @param [CursorSetImpl] cset 
  # @param [Cursor] cursor 
  # @return [Integer] zero if the CXCursor was already in the set, and non-zero otherwise.
  # @scope class
  attach_function :cx_cursor_set_insert, :clang_CXCursorSet_insert, [CursorSetImpl, Cursor.by_value], :uint
  
  # Determine the semantic parent of the given cursor.
  # 
  # The semantic parent of a cursor is the cursor that semantically contains
  # the given \p cursor. For many declarations, the lexical and semantic parents
  # are equivalent (the lexical parent is returned by 
  # \c clang_getCursorLexicalParent()). They diverge when declarations or
  # definitions are provided out-of-line. For example:
  # 
  # \code
  # class C {
  #  void f();
  # };
  # 
  # void C::f() { }
  # \endcode
  # 
  # In the out-of-line definition of \c C::f, the semantic parent is the 
  # the class \c C, of which this function is a member. The lexical parent is
  # the place where the declaration actually occurs in the source code; in this
  # case, the definition occurs in the translation unit. In general, the 
  # lexical parent for a given entity can change without affecting the semantics
  # of the program, and the lexical parent of different declarations of the
  # same entity may be different. Changing the semantic parent of a declaration,
  # on the other hand, can have a major impact on semantics, and redeclarations
  # of a particular entity should all have the same semantic context.
  # 
  # In the example above, both declarations of \c C::f have \c C as their
  # semantic context, while the lexical context of the first \c C::f is \c C
  # and the lexical context of the second \c C::f is the translation unit.
  # 
  # For global declarations, the semantic parent is the translation unit.
  # 
  # @method get_cursor_semantic_parent(cursor)
  # @param [Cursor] cursor 
  # @return [Cursor] 
  # @scope class
  attach_function :get_cursor_semantic_parent, :clang_getCursorSemanticParent, [Cursor.by_value], Cursor.by_value
  
  # Determine the lexical parent of the given cursor.
  # 
  # The lexical parent of a cursor is the cursor in which the given \p cursor
  # was actually written. For many declarations, the lexical and semantic parents
  # are equivalent (the semantic parent is returned by 
  # \c clang_getCursorSemanticParent()). They diverge when declarations or
  # definitions are provided out-of-line. For example:
  # 
  # \code
  # class C {
  #  void f();
  # };
  # 
  # void C::f() { }
  # \endcode
  # 
  # In the out-of-line definition of \c C::f, the semantic parent is the 
  # the class \c C, of which this function is a member. The lexical parent is
  # the place where the declaration actually occurs in the source code; in this
  # case, the definition occurs in the translation unit. In general, the 
  # lexical parent for a given entity can change without affecting the semantics
  # of the program, and the lexical parent of different declarations of the
  # same entity may be different. Changing the semantic parent of a declaration,
  # on the other hand, can have a major impact on semantics, and redeclarations
  # of a particular entity should all have the same semantic context.
  # 
  # In the example above, both declarations of \c C::f have \c C as their
  # semantic context, while the lexical context of the first \c C::f is \c C
  # and the lexical context of the second \c C::f is the translation unit.
  # 
  # For declarations written in the global scope, the lexical parent is
  # the translation unit.
  # 
  # @method get_cursor_lexical_parent(cursor)
  # @param [Cursor] cursor 
  # @return [Cursor] 
  # @scope class
  attach_function :get_cursor_lexical_parent, :clang_getCursorLexicalParent, [Cursor.by_value], Cursor.by_value
  
  # Determine the set of methods that are overridden by the given
  # method.
  # 
  # In both Objective-C and C++, a method (aka virtual member function,
  # in C++) can override a virtual method in a base class. For
  # Objective-C, a method is said to override any method in the class's
  # interface (if we're coming from an implementation), its protocols,
  # or its categories, that has the same selector and is of the same
  # kind (class or instance). If no such method exists, the search
  # continues to the class's superclass, its protocols, and its
  # categories, and so on.
  # 
  # For C++, a virtual member function overrides any virtual member
  # function with the same signature that occurs in its base
  # classes. With multiple inheritance, a virtual member function can
  # override several virtual member functions coming from different
  # base classes.
  # 
  # In all cases, this function determines the immediate overridden
  # method, rather than all of the overridden methods. For example, if
  # a method is originally declared in a class A, then overridden in B
  # (which in inherits from A) and also in C (which inherited from B),
  # then the only overridden method returned from this function when
  # invoked on C's method will be B's method. The client may then
  # invoke this function again, given the previously-found overridden
  # methods, to map out the complete method-override set.
  # 
  # @method get_overridden_cursors(cursor, overridden, num_overridden)
  # @param [Cursor] cursor A cursor representing an Objective-C or C++
  #   method. This routine will compute the set of methods that this
  #   method overrides.
  # @param [FFI::Pointer(**Cursor)] overridden A pointer whose pointee will be replaced with a
  #   pointer to an array of cursors, representing the set of overridden
  #   methods. If there are no overridden methods, the pointee will be
  #   set to NULL. The pointee must be freed via a call to 
  #   \c clang_disposeOverriddenCursors().
  # @param [FFI::Pointer(*UInt)] num_overridden A pointer to the number of overridden
  #   functions, will be set to the number of overridden functions in the
  #   array pointed to by \p overridden.
  # @return [nil] 
  # @scope class
  attach_function :get_overridden_cursors, :clang_getOverriddenCursors, [Cursor.by_value, :pointer, :pointer], :void
  
  # Free the set of overridden cursors returned by \c
  # clang_getOverriddenCursors().
  # 
  # @method dispose_overridden_cursors(overridden)
  # @param [Cursor] overridden 
  # @return [nil] 
  # @scope class
  attach_function :dispose_overridden_cursors, :clang_disposeOverriddenCursors, [Cursor], :void
  
  # Retrieve the file that is included by the given inclusion directive
  # cursor.
  # 
  # @method get_included_file(cursor)
  # @param [Cursor] cursor 
  # @return [FFI::Pointer(File)] 
  # @scope class
  attach_function :get_included_file, :clang_getIncludedFile, [Cursor.by_value], :pointer
  
  # Map a source location to the cursor that describes the entity at that
  # location in the source code.
  # 
  # clang_getCursor() maps an arbitrary source location within a translation
  # unit down to the most specific cursor that describes the entity at that
  # location. For example, given an expression \c x + y, invoking
  # clang_getCursor() with a source location pointing to "x" will return the
  # cursor for "x"; similarly for "y". If the cursor points anywhere between
  # "x" or "y" (e.g., on the + or the whitespace around it), clang_getCursor()
  # will return a cursor referring to the "+" expression.
  # 
  # @method get_cursor(translation_unit_impl, source_location)
  # @param [TranslationUnitImpl] translation_unit_impl 
  # @param [SourceLocation] source_location 
  # @return [Cursor] a cursor representing the entity at the given source location, or
  #   a NULL cursor if no such entity can be found.
  # @scope class
  attach_function :get_cursor, :clang_getCursor, [TranslationUnitImpl, SourceLocation.by_value], Cursor.by_value
  
  # Retrieve the physical location of the source constructor referenced
  # by the given cursor.
  # 
  # The location of a declaration is typically the location of the name of that
  # declaration, where the name of that declaration would occur if it is
  # unnamed, or some keyword that introduces that particular declaration.
  # The location of a reference is where that reference occurs within the
  # source code.
  # 
  # @method get_cursor_location(cursor)
  # @param [Cursor] cursor 
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_cursor_location, :clang_getCursorLocation, [Cursor.by_value], SourceLocation.by_value
  
  # Retrieve the physical extent of the source construct referenced by
  # the given cursor.
  # 
  # The extent of a cursor starts with the file/line/column pointing at the
  # first character within the source construct that the cursor refers to and
  # ends with the last character withinin that source construct. For a
  # declaration, the extent covers the declaration itself. For a reference,
  # the extent covers the location of the reference (e.g., where the referenced
  # entity was actually used).
  # 
  # @method get_cursor_extent(cursor)
  # @param [Cursor] cursor 
  # @return [SourceRange] 
  # @scope class
  attach_function :get_cursor_extent, :clang_getCursorExtent, [Cursor.by_value], SourceRange.by_value
  
  # Describes the kind of type
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:type_kind).</em>
  # 
  # === Options:
  # :invalid ::
  #   Reprents an invalid type (e.g., where no type is available).
  # :unexposed ::
  #   A type whose specific kind is not exposed via this
  #   interface.
  # :void ::
  #   Builtin types
  # :bool ::
  #   
  # :char_u ::
  #   
  # :u_char ::
  #   
  # :char16 ::
  #   
  # :char32 ::
  #   
  # :u_short ::
  #   
  # :u_int ::
  #   
  # :u_long ::
  #   
  # :u_long_long ::
  #   
  # :u_int128 ::
  #   
  # :char_s ::
  #   
  # :s_char ::
  #   
  # :w_char ::
  #   
  # :short ::
  #   
  # :int ::
  #   
  # :long ::
  #   
  # :long_long ::
  #   
  # :int128 ::
  #   
  # :float ::
  #   
  # :double ::
  #   
  # :long_double ::
  #   
  # :null_ptr ::
  #   
  # :overload ::
  #   
  # :dependent ::
  #   
  # :obj_c_id ::
  #   
  # :obj_c_class ::
  #   
  # :obj_c_sel ::
  #   
  # :complex ::
  #   
  # :pointer ::
  #   
  # :block_pointer ::
  #   
  # :l_value_reference ::
  #   
  # :r_value_reference ::
  #   
  # :record ::
  #   
  # :enum ::
  #   
  # :typedef ::
  #   
  # :obj_c_interface ::
  #   
  # :obj_c_object_pointer ::
  #   
  # :function_no_proto ::
  #   
  # :function_proto ::
  #   
  # :constant_array ::
  #   
  # 
  # @method _enum_type_kind_
  # @return [Symbol]
  # @scope class
  enum :type_kind, [
    :invalid, 0,
    :unexposed, 1,
    :void, 2,
    :bool, 3,
    :char_u, 4,
    :u_char, 5,
    :char16, 6,
    :char32, 7,
    :u_short, 8,
    :u_int, 9,
    :u_long, 10,
    :u_long_long, 11,
    :u_int128, 12,
    :char_s, 13,
    :s_char, 14,
    :w_char, 15,
    :short, 16,
    :int, 17,
    :long, 18,
    :long_long, 19,
    :int128, 20,
    :float, 21,
    :double, 22,
    :long_double, 23,
    :null_ptr, 24,
    :overload, 25,
    :dependent, 26,
    :obj_c_id, 27,
    :obj_c_class, 28,
    :obj_c_sel, 29,
    :complex, 100,
    :pointer, 101,
    :block_pointer, 102,
    :l_value_reference, 103,
    :r_value_reference, 104,
    :record, 105,
    :enum, 106,
    :typedef, 107,
    :obj_c_interface, 108,
    :obj_c_object_pointer, 109,
    :function_no_proto, 110,
    :function_proto, 111,
    :constant_array, 112
  ]
  
  # Retrieve the type of a CXCursor (if any).
  # 
  # @method get_cursor_type(c)
  # @param [Cursor] c 
  # @return [Type] 
  # @scope class
  attach_function :get_cursor_type, :clang_getCursorType, [Cursor.by_value], Type.by_value
  
  # Determine whether two CXTypes represent the same type.
  # 
  # @method equal_types(a, b)
  # @param [Type] a 
  # @param [Type] b 
  # @return [Integer] non-zero if the CXTypes represent the same type and 
  #               zero otherwise.
  # @scope class
  attach_function :equal_types, :clang_equalTypes, [Type.by_value, Type.by_value], :uint
  
  # Return the canonical type for a CXType.
  # 
  # Clang's type system explicitly models typedefs and all the ways
  # a specific type can be represented.  The canonical type is the underlying
  # type with all the "sugar" removed.  For example, if 'T' is a typedef
  # for 'int', the canonical type for 'T' would be 'int'.
  # 
  # @method get_canonical_type(t)
  # @param [Type] t 
  # @return [Type] 
  # @scope class
  attach_function :get_canonical_type, :clang_getCanonicalType, [Type.by_value], Type.by_value
  
  #  Determine whether a CXType has the "const" qualifier set, 
  #  without looking through typedefs that may have added "const" at a different level.
  # 
  # @method is_const_qualified_type(t)
  # @param [Type] t 
  # @return [Integer] 
  # @scope class
  attach_function :is_const_qualified_type, :clang_isConstQualifiedType, [Type.by_value], :uint
  
  #  Determine whether a CXType has the "volatile" qualifier set,
  #  without looking through typedefs that may have added "volatile" at a different level.
  # 
  # @method is_volatile_qualified_type(t)
  # @param [Type] t 
  # @return [Integer] 
  # @scope class
  attach_function :is_volatile_qualified_type, :clang_isVolatileQualifiedType, [Type.by_value], :uint
  
  #  Determine whether a CXType has the "restrict" qualifier set,
  #  without looking through typedefs that may have added "restrict" at a different level.
  # 
  # @method is_restrict_qualified_type(t)
  # @param [Type] t 
  # @return [Integer] 
  # @scope class
  attach_function :is_restrict_qualified_type, :clang_isRestrictQualifiedType, [Type.by_value], :uint
  
  # For pointer types, returns the type of the pointee.
  # 
  # @method get_pointee_type(t)
  # @param [Type] t 
  # @return [Type] 
  # @scope class
  attach_function :get_pointee_type, :clang_getPointeeType, [Type.by_value], Type.by_value
  
  # Return the cursor for the declaration of the given type.
  # 
  # @method get_type_declaration(t)
  # @param [Type] t 
  # @return [Cursor] 
  # @scope class
  attach_function :get_type_declaration, :clang_getTypeDeclaration, [Type.by_value], Cursor.by_value
  
  # Returns the Objective-C type encoding for the specified declaration.
  # 
  # @method get_decl_obj_c_type_encoding(c)
  # @param [Cursor] c 
  # @return [String] 
  # @scope class
  attach_function :get_decl_obj_c_type_encoding, :clang_getDeclObjCTypeEncoding, [Cursor.by_value], String.by_value
  
  # Retrieve the spelling of a given CXTypeKind.
  # 
  # @method get_type_kind_spelling(k)
  # @param [Symbol from _enum_type_kind_] k 
  # @return [String] 
  # @scope class
  attach_function :get_type_kind_spelling, :clang_getTypeKindSpelling, [:type_kind], String.by_value
  
  # Retrieve the result type associated with a function type.
  # 
  # @method get_result_type(t)
  # @param [Type] t 
  # @return [Type] 
  # @scope class
  attach_function :get_result_type, :clang_getResultType, [Type.by_value], Type.by_value
  
  # Retrieve the result type associated with a given cursor.  This only
  #  returns a valid type of the cursor refers to a function or method.
  # 
  # @method get_cursor_result_type(c)
  # @param [Cursor] c 
  # @return [Type] 
  # @scope class
  attach_function :get_cursor_result_type, :clang_getCursorResultType, [Cursor.by_value], Type.by_value
  
  # Return 1 if the CXType is a POD (plain old data) type, and 0
  #  otherwise.
  # 
  # @method is_pod_type(t)
  # @param [Type] t 
  # @return [Integer] 
  # @scope class
  attach_function :is_pod_type, :clang_isPODType, [Type.by_value], :uint
  
  # Return the element type of an array type.
  # 
  # If a non-array type is passed in, an invalid type is returned.
  # 
  # @method get_array_element_type(t)
  # @param [Type] t 
  # @return [Type] 
  # @scope class
  attach_function :get_array_element_type, :clang_getArrayElementType, [Type.by_value], Type.by_value
  
  # Return the the array size of a constant array.
  # 
  # If a non-array type is passed in, -1 is returned.
  # 
  # @method get_array_size(t)
  # @param [Type] t 
  # @return [Integer] 
  # @scope class
  attach_function :get_array_size, :clang_getArraySize, [Type.by_value], :long_long
  
  # Returns 1 if the base class specified by the cursor with kind
  #   CX_CXXBaseSpecifier is virtual.
  # 
  # @method is_virtual_base(cursor)
  # @param [Cursor] cursor 
  # @return [Integer] 
  # @scope class
  attach_function :is_virtual_base, :clang_isVirtualBase, [Cursor.by_value], :uint
  
  # Represents the C++ access control level to a base class for a
  # cursor with kind CX_CXXBaseSpecifier.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:cxx_access_specifier).</em>
  # 
  # === Options:
  # :x_invalid_access_specifier ::
  #   
  # :x_public ::
  #   
  # :x_protected ::
  #   
  # :x_private ::
  #   
  # 
  # @method _enum_cxx_access_specifier_
  # @return [Symbol]
  # @scope class
  enum :cxx_access_specifier, [
    :x_invalid_access_specifier,
    :x_public,
    :x_protected,
    :x_private
  ]
  
  # Returns the access control level for the C++ base specifier
  # represented by a cursor with kind CXCursor_CXXBaseSpecifier or
  # CXCursor_AccessSpecifier.
  # 
  # @method get_cxx_access_specifier(cursor)
  # @param [Cursor] cursor 
  # @return [Symbol from _enum_cxx_access_specifier_] 
  # @scope class
  attach_function :get_cxx_access_specifier, :clang_getCXXAccessSpecifier, [Cursor.by_value], :cxx_access_specifier
  
  # Determine the number of overloaded declarations referenced by a 
  # \c CXCursor_OverloadedDeclRef cursor.
  # 
  # @method get_num_overloaded_decls(cursor)
  # @param [Cursor] cursor The cursor whose overloaded declarations are being queried.
  # @return [Integer] The number of overloaded declarations referenced by \c cursor. If it
  #   is not a \c CXCursor_OverloadedDeclRef cursor, returns 0.
  # @scope class
  attach_function :get_num_overloaded_decls, :clang_getNumOverloadedDecls, [Cursor.by_value], :uint
  
  # Retrieve a cursor for one of the overloaded declarations referenced
  # by a \c CXCursor_OverloadedDeclRef cursor.
  # 
  # @method get_overloaded_decl(cursor, index)
  # @param [Cursor] cursor The cursor whose overloaded declarations are being queried.
  # @param [Integer] index The zero-based index into the set of overloaded declarations in
  #   the cursor.
  # @return [Cursor] A cursor representing the declaration referenced by the given 
  #   \c cursor at the specified \c index. If the cursor does not have an 
  #   associated set of overloaded declarations, or if the index is out of bounds,
  #   returns \c clang_getNullCursor();
  # @scope class
  attach_function :get_overloaded_decl, :clang_getOverloadedDecl, [Cursor.by_value, :uint], Cursor.by_value
  
  # For cursors representing an iboutletcollection attribute,
  #  this function returns the collection element type.
  # 
  # @method get_ib_outlet_collection_type(cursor)
  # @param [Cursor] cursor 
  # @return [Type] 
  # @scope class
  attach_function :get_ib_outlet_collection_type, :clang_getIBOutletCollectionType, [Cursor.by_value], Type.by_value
  
  # Describes how the traversal of the children of a particular
  # cursor should proceed after visiting a particular child cursor.
  # 
  # A value of this enumeration type should be returned by each
  # \c CXCursorVisitor to indicate how clang_visitChildren() proceed.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:child_visit_result).</em>
  # 
  # === Options:
  # :break ::
  #   Terminates the cursor traversal.
  # :continue ::
  #   Continues the cursor traversal with the next sibling of
  #   the cursor just visited, without visiting its children.
  # :recurse ::
  #   Recursively traverse the children of this cursor, using
  #   the same visitor and client data.
  # 
  # @method _enum_child_visit_result_
  # @return [Symbol]
  # @scope class
  enum :child_visit_result, [
    :break,
    :continue,
    :recurse
  ]
  
  # Visitor invoked for each cursor found by a traversal.
  # 
  # This visitor function will be invoked for each cursor found by
  # clang_visitCursorChildren(). Its first argument is the cursor being
  # visited, its second argument is the parent visitor for that cursor,
  # and its third argument is the client data provided to
  # clang_visitCursorChildren().
  # 
  # The visitor should return one of the \c CXChildVisitResult values
  # to direct clang_visitCursorChildren().
  # 
  # <em>This entry is only for documentation and no real method.</em>
  # 
  # @method _callback_cursor_visitor_(cursor, parent, client_data)
  # @param [Cursor] cursor 
  # @param [Cursor] parent 
  # @param [FFI::Pointer(ClientData)] client_data 
  # @return [Symbol from _enum_child_visit_result_] 
  # @scope class
  callback :cursor_visitor, [Cursor.by_value, Cursor.by_value, :pointer], :child_visit_result
  
  # Visit the children of a particular cursor.
  # 
  # This function visits all the direct children of the given cursor,
  # invoking the given \p visitor function with the cursors of each
  # visited child. The traversal may be recursive, if the visitor returns
  # \c CXChildVisit_Recurse. The traversal may also be ended prematurely, if
  # the visitor returns \c CXChildVisit_Break.
  # 
  # @method visit_children(parent, visitor, client_data)
  # @param [Cursor] parent the cursor whose child may be visited. All kinds of
  #   cursors can be visited, including invalid cursors (which, by
  #   definition, have no children).
  # @param [Proc(_callback_cursor_visitor_)] visitor the visitor function that will be invoked for each
  #   child of \p parent.
  # @param [FFI::Pointer(ClientData)] client_data pointer data supplied by the client, which will
  #   be passed to the visitor each time it is invoked.
  # @return [Integer] a non-zero value if the traversal was terminated
  #   prematurely by the visitor returning \c CXChildVisit_Break.
  # @scope class
  attach_function :visit_children, :clang_visitChildren, [Cursor.by_value, :cursor_visitor, :pointer], :uint
  
  # Retrieve a Unified Symbol Resolution (USR) for the entity referenced
  # by the given cursor.
  # 
  # A Unified Symbol Resolution (USR) is a string that identifies a particular
  # entity (function, class, variable, etc.) within a program. USRs can be
  # compared across translation units to determine, e.g., when references in
  # one translation refer to an entity defined in another translation unit.
  # 
  # @method get_cursor_usr(cursor)
  # @param [Cursor] cursor 
  # @return [String] 
  # @scope class
  attach_function :get_cursor_usr, :clang_getCursorUSR, [Cursor.by_value], String.by_value
  
  # Construct a USR for a specified Objective-C class.
  # 
  # @method construct_usr_obj_c_class(class_name)
  # @param [String] class_name 
  # @return [String] 
  # @scope class
  attach_function :construct_usr_obj_c_class, :clang_constructUSR_ObjCClass, [:string], String.by_value
  
  # Construct a USR for a specified Objective-C category.
  # 
  # @method construct_usr_obj_c_category(class_name, category_name)
  # @param [String] class_name 
  # @param [String] category_name 
  # @return [String] 
  # @scope class
  attach_function :construct_usr_obj_c_category, :clang_constructUSR_ObjCCategory, [:string, :string], String.by_value
  
  # Construct a USR for a specified Objective-C protocol.
  # 
  # @method construct_usr_obj_c_protocol(protocol_name)
  # @param [String] protocol_name 
  # @return [String] 
  # @scope class
  attach_function :construct_usr_obj_c_protocol, :clang_constructUSR_ObjCProtocol, [:string], String.by_value
  
  # Construct a USR for a specified Objective-C instance variable and
  #   the USR for its containing class.
  # 
  # @method construct_usr_obj_c_ivar(name, class_usr)
  # @param [String] name 
  # @param [String] class_usr 
  # @return [String] 
  # @scope class
  attach_function :construct_usr_obj_c_ivar, :clang_constructUSR_ObjCIvar, [:string, String.by_value], String.by_value
  
  # Construct a USR for a specified Objective-C method and
  #   the USR for its containing class.
  # 
  # @method construct_usr_obj_c_method(name, is_instance_method, class_usr)
  # @param [String] name 
  # @param [Integer] is_instance_method 
  # @param [String] class_usr 
  # @return [String] 
  # @scope class
  attach_function :construct_usr_obj_c_method, :clang_constructUSR_ObjCMethod, [:string, :uint, String.by_value], String.by_value
  
  # Construct a USR for a specified Objective-C property and the USR
  #  for its containing class.
  # 
  # @method construct_usr_obj_c_property(property, class_usr)
  # @param [String] property 
  # @param [String] class_usr 
  # @return [String] 
  # @scope class
  attach_function :construct_usr_obj_c_property, :clang_constructUSR_ObjCProperty, [:string, String.by_value], String.by_value
  
  # Retrieve a name for the entity referenced by this cursor.
  # 
  # @method get_cursor_spelling(cursor)
  # @param [Cursor] cursor 
  # @return [String] 
  # @scope class
  attach_function :get_cursor_spelling, :clang_getCursorSpelling, [Cursor.by_value], String.by_value
  
  # Retrieve the display name for the entity referenced by this cursor.
  # 
  # The display name contains extra information that helps identify the cursor,
  # such as the parameters of a function or template or the arguments of a 
  # class template specialization.
  # 
  # @method get_cursor_display_name(cursor)
  # @param [Cursor] cursor 
  # @return [String] 
  # @scope class
  attach_function :get_cursor_display_name, :clang_getCursorDisplayName, [Cursor.by_value], String.by_value
  
  # For a cursor that is a reference, retrieve a cursor representing the
  # entity that it references.
  # 
  # Reference cursors refer to other entities in the AST. For example, an
  # Objective-C superclass reference cursor refers to an Objective-C class.
  # This function produces the cursor for the Objective-C class from the
  # cursor for the superclass reference. If the input cursor is a declaration or
  # definition, it returns that declaration or definition unchanged.
  # Otherwise, returns the NULL cursor.
  # 
  # @method get_cursor_referenced(cursor)
  # @param [Cursor] cursor 
  # @return [Cursor] 
  # @scope class
  attach_function :get_cursor_referenced, :clang_getCursorReferenced, [Cursor.by_value], Cursor.by_value
  
  #  For a cursor that is either a reference to or a declaration
  #  of some entity, retrieve a cursor that describes the definition of
  #  that entity.
  # 
  #  Some entities can be declared multiple times within a translation
  #  unit, but only one of those declarations can also be a
  #  definition. For example, given:
  # 
  #  \code
  #  int f(int, int);
  #  int g(int x, int y) { return f(x, y); }
  #  int f(int a, int b) { return a + b; }
  #  int f(int, int);
  #  \endcode
  # 
  #  there are three declarations of the function "f", but only the
  #  second one is a definition. The clang_getCursorDefinition()
  #  function will take any cursor pointing to a declaration of "f"
  #  (the first or fourth lines of the example) or a cursor referenced
  #  that uses "f" (the call to "f' inside "g") and will return a
  #  declaration cursor pointing to the definition (the second "f"
  #  declaration).
  # 
  #  If given a cursor for which there is no corresponding definition,
  #  e.g., because there is no definition of that entity within this
  #  translation unit, returns a NULL cursor.
  # 
  # @method get_cursor_definition(cursor)
  # @param [Cursor] cursor 
  # @return [Cursor] 
  # @scope class
  attach_function :get_cursor_definition, :clang_getCursorDefinition, [Cursor.by_value], Cursor.by_value
  
  # Determine whether the declaration pointed to by this cursor
  # is also a definition of that entity.
  # 
  # @method is_cursor_definition(cursor)
  # @param [Cursor] cursor 
  # @return [Integer] 
  # @scope class
  attach_function :is_cursor_definition, :clang_isCursorDefinition, [Cursor.by_value], :uint
  
  # Retrieve the canonical cursor corresponding to the given cursor.
  # 
  # In the C family of languages, many kinds of entities can be declared several
  # times within a single translation unit. For example, a structure type can
  # be forward-declared (possibly multiple times) and later defined:
  # 
  # \code
  # struct X;
  # struct X;
  # struct X {
  #   int member;
  # };
  # \endcode
  # 
  # The declarations and the definition of \c X are represented by three 
  # different cursors, all of which are declarations of the same underlying 
  # entity. One of these cursor is considered the "canonical" cursor, which
  # is effectively the representative for the underlying entity. One can 
  # determine if two cursors are declarations of the same underlying entity by
  # comparing their canonical cursors.
  # 
  # @method get_canonical_cursor(cursor)
  # @param [Cursor] cursor 
  # @return [Cursor] The canonical cursor for the entity referred to by the given cursor.
  # @scope class
  attach_function :get_canonical_cursor, :clang_getCanonicalCursor, [Cursor.by_value], Cursor.by_value
  
  # Determine if a C++ member function or member function template is 
  # declared 'static'.
  # 
  # @method cxx_method_is_static(c)
  # @param [Cursor] c 
  # @return [Integer] 
  # @scope class
  attach_function :cxx_method_is_static, :clang_CXXMethod_isStatic, [Cursor.by_value], :uint
  
  # Determine if a C++ member function or member function template is
  # explicitly declared 'virtual' or if it overrides a virtual method from
  # one of the base classes.
  # 
  # @method cxx_method_is_virtual(c)
  # @param [Cursor] c 
  # @return [Integer] 
  # @scope class
  attach_function :cxx_method_is_virtual, :clang_CXXMethod_isVirtual, [Cursor.by_value], :uint
  
  # Given a cursor that represents a template, determine
  # the cursor kind of the specializations would be generated by instantiating
  # the template.
  # 
  # This routine can be used to determine what flavor of function template,
  # class template, or class template partial specialization is stored in the
  # cursor. For example, it can describe whether a class template cursor is
  # declared with "struct", "class" or "union".
  # 
  # @method get_template_cursor_kind(c)
  # @param [Cursor] c The cursor to query. This cursor should represent a template
  #   declaration.
  # @return [Symbol from _enum_cursor_kind_] The cursor kind of the specializations that would be generated
  #   by instantiating the template \p C. If \p C is not a template, returns
  #   \c CXCursor_NoDeclFound.
  # @scope class
  attach_function :get_template_cursor_kind, :clang_getTemplateCursorKind, [Cursor.by_value], :cursor_kind
  
  # Given a cursor that may represent a specialization or instantiation
  # of a template, retrieve the cursor that represents the template that it
  # specializes or from which it was instantiated.
  # 
  # This routine determines the template involved both for explicit 
  # specializations of templates and for implicit instantiations of the template,
  # both of which are referred to as "specializations". For a class template
  # specialization (e.g., \c std::vector<bool>), this routine will return 
  # either the primary template (\c std::vector) or, if the specialization was
  # instantiated from a class template partial specialization, the class template
  # partial specialization. For a class template partial specialization and a
  # function template specialization (including instantiations), this
  # this routine will return the specialized template.
  # 
  # For members of a class template (e.g., member functions, member classes, or
  # static data members), returns the specialized or instantiated member. 
  # Although not strictly "templates" in the C++ language, members of class
  # templates have the same notions of specializations and instantiations that
  # templates do, so this routine treats them similarly.
  # 
  # @method get_specialized_cursor_template(c)
  # @param [Cursor] c A cursor that may be a specialization of a template or a member
  #   of a template.
  # @return [Cursor] If the given cursor is a specialization or instantiation of a 
  #   template or a member thereof, the template or member that it specializes or
  #   from which it was instantiated. Otherwise, returns a NULL cursor.
  # @scope class
  attach_function :get_specialized_cursor_template, :clang_getSpecializedCursorTemplate, [Cursor.by_value], Cursor.by_value
  
  # Given a cursor that references something else, return the source range
  # covering that reference.
  # 
  # @method get_cursor_reference_name_range(c, name_flags, piece_index)
  # @param [Cursor] c A cursor pointing to a member reference, a declaration reference, or
  #   an operator call.
  # @param [Integer] name_flags A bitset with three independent flags: 
  #   CXNameRange_WantQualifier, CXNameRange_WantTemplateArgs, and
  #   CXNameRange_WantSinglePiece.
  # @param [Integer] piece_index For contiguous names or when passing the flag 
  #   CXNameRange_WantSinglePiece, only one piece with index 0 is 
  #   available. When the CXNameRange_WantSinglePiece flag is not passed for a
  #   non-contiguous names, this index can be used to retreive the individual
  #   pieces of the name. See also CXNameRange_WantSinglePiece.
  # @return [SourceRange] The piece of the name pointed to by the given cursor. If there is no
  #   name, or if the PieceIndex is out-of-range, a null-cursor will be returned.
  # @scope class
  attach_function :get_cursor_reference_name_range, :clang_getCursorReferenceNameRange, [Cursor.by_value, :uint, :uint], SourceRange.by_value
  
  # (Not documented)
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:name_ref_flags).</em>
  # 
  # === Options:
  # :want_qualifier ::
  #   Include the nested-name-specifier, e.g. Foo:: in x.Foo::y, in the
  #   range.
  # :want_template_args ::
  #   Include the explicit template arguments, e.g. <int> in x.f<int>, in 
  #   the range.
  # :want_single_piece ::
  #   If the name is non-contiguous, return the full spanning range.
  #   
  #   Non-contiguous names occur in Objective-C when a selector with two or more
  #   parameters is used, or in C++ when using an operator:
  #   \code
  #   (object doSomething:here withValue:there); // ObjC
  #   return some_vector(1); // C++
  #   \endcode
  # 
  # @method _enum_name_ref_flags_
  # @return [Symbol]
  # @scope class
  enum :name_ref_flags, [
    :want_qualifier, 0x1,
    :want_template_args, 0x2,
    :want_single_piece, 0x4
  ]
  
  # Describes a kind of token.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:token_kind).</em>
  # 
  # === Options:
  # :punctuation ::
  #   A token that contains some kind of punctuation.
  # :keyword ::
  #   A language keyword.
  # :identifier ::
  #   An identifier (that is not a keyword).
  # :literal ::
  #   A numeric, string, or character literal.
  # :comment ::
  #   A comment.
  # 
  # @method _enum_token_kind_
  # @return [Symbol]
  # @scope class
  enum :token_kind, [
    :punctuation,
    :keyword,
    :identifier,
    :literal,
    :comment
  ]
  
  # Determine the kind of the given token.
  # 
  # @method get_token_kind(token)
  # @param [Token] token 
  # @return [Symbol from _enum_token_kind_] 
  # @scope class
  attach_function :get_token_kind, :clang_getTokenKind, [Token.by_value], :token_kind
  
  # Determine the spelling of the given token.
  # 
  # The spelling of a token is the textual representation of that token, e.g.,
  # the text of an identifier or keyword.
  # 
  # @method get_token_spelling(translation_unit_impl, token)
  # @param [TranslationUnitImpl] translation_unit_impl 
  # @param [Token] token 
  # @return [String] 
  # @scope class
  attach_function :get_token_spelling, :clang_getTokenSpelling, [TranslationUnitImpl, Token.by_value], String.by_value
  
  # Retrieve the source location of the given token.
  # 
  # @method get_token_location(translation_unit_impl, token)
  # @param [TranslationUnitImpl] translation_unit_impl 
  # @param [Token] token 
  # @return [SourceLocation] 
  # @scope class
  attach_function :get_token_location, :clang_getTokenLocation, [TranslationUnitImpl, Token.by_value], SourceLocation.by_value
  
  # Retrieve a source range that covers the given token.
  # 
  # @method get_token_extent(translation_unit_impl, token)
  # @param [TranslationUnitImpl] translation_unit_impl 
  # @param [Token] token 
  # @return [SourceRange] 
  # @scope class
  attach_function :get_token_extent, :clang_getTokenExtent, [TranslationUnitImpl, Token.by_value], SourceRange.by_value
  
  # Tokenize the source code described by the given range into raw
  # lexical tokens.
  # 
  # @method tokenize(tu, range, tokens, num_tokens)
  # @param [TranslationUnitImpl] tu the translation unit whose text is being tokenized.
  # @param [SourceRange] range the source range in which text should be tokenized. All of the
  #   tokens produced by tokenization will fall within this source range,
  # @param [FFI::Pointer(**Token)] tokens this pointer will be set to point to the array of tokens
  #   that occur within the given source range. The returned pointer must be
  #   freed with clang_disposeTokens() before the translation unit is destroyed.
  # @param [FFI::Pointer(*UInt)] num_tokens will be set to the number of tokens in the \c *Tokens
  #   array.
  # @return [nil] 
  # @scope class
  attach_function :tokenize, :clang_tokenize, [TranslationUnitImpl, SourceRange.by_value, :pointer, :pointer], :void
  
  # Annotate the given set of tokens by providing cursors for each token
  # that can be mapped to a specific entity within the abstract syntax tree.
  # 
  # This token-annotation routine is equivalent to invoking
  # clang_getCursor() for the source locations of each of the
  # tokens. The cursors provided are filtered, so that only those
  # cursors that have a direct correspondence to the token are
  # accepted. For example, given a function call \c f(x),
  # clang_getCursor() would provide the following cursors:
  # 
  #   * when the cursor is over the 'f', a DeclRefExpr cursor referring to 'f'.
  #   * when the cursor is over the '(' or the ')', a CallExpr referring to 'f'.
  #   * when the cursor is over the 'x', a DeclRefExpr cursor referring to 'x'.
  # 
  # Only the first and last of these cursors will occur within the
  # annotate, since the tokens "f" and "x' directly refer to a function
  # and a variable, respectively, but the parentheses are just a small
  # part of the full syntax of the function call expression, which is
  # not provided as an annotation.
  # 
  # @method annotate_tokens(tu, tokens, num_tokens, cursors)
  # @param [TranslationUnitImpl] tu the translation unit that owns the given tokens.
  # @param [Token] tokens the set of tokens to annotate.
  # @param [Integer] num_tokens the number of tokens in \p Tokens.
  # @param [Cursor] cursors an array of \p NumTokens cursors, whose contents will be
  #   replaced with the cursors corresponding to each token.
  # @return [nil] 
  # @scope class
  attach_function :annotate_tokens, :clang_annotateTokens, [TranslationUnitImpl, Token, :uint, Cursor], :void
  
  # Free the given set of tokens.
  # 
  # @method dispose_tokens(tu, tokens, num_tokens)
  # @param [TranslationUnitImpl] tu 
  # @param [Token] tokens 
  # @param [Integer] num_tokens 
  # @return [nil] 
  # @scope class
  attach_function :dispose_tokens, :clang_disposeTokens, [TranslationUnitImpl, Token, :uint], :void
  
  # for debug/testing
  # 
  # @method get_cursor_kind_spelling(kind)
  # @param [Symbol from _enum_cursor_kind_] kind 
  # @return [String] 
  # @scope class
  attach_function :get_cursor_kind_spelling, :clang_getCursorKindSpelling, [:cursor_kind], String.by_value
  
  # (Not documented)
  # 
  # @method get_definition_spelling_and_extent(cursor, start_buf, end_buf, start_line, start_column, end_line, end_column)
  # @param [Cursor] cursor 
  # @param [FFI::Pointer(**Char_S)] start_buf 
  # @param [FFI::Pointer(**Char_S)] end_buf 
  # @param [FFI::Pointer(*UInt)] start_line 
  # @param [FFI::Pointer(*UInt)] start_column 
  # @param [FFI::Pointer(*UInt)] end_line 
  # @param [FFI::Pointer(*UInt)] end_column 
  # @return [nil] 
  # @scope class
  attach_function :get_definition_spelling_and_extent, :clang_getDefinitionSpellingAndExtent, [Cursor.by_value, :pointer, :pointer, :pointer, :pointer, :pointer, :pointer], :void
  
  # (Not documented)
  # 
  # @method enable_stack_traces()
  # @return [nil] 
  # @scope class
  attach_function :enable_stack_traces, :clang_enableStackTraces, [], :void
  
  # (Not documented)
  # 
  # @method execute_on_thread(fn, user_data, stack_size)
  # @param [FFI::Pointer(*)] fn 
  # @param [FFI::Pointer(*Void)] user_data 
  # @param [Integer] stack_size 
  # @return [nil] 
  # @scope class
  attach_function :execute_on_thread, :clang_executeOnThread, [:pointer, :pointer, :uint], :void
  
  # A single result of code completion.
  # 
  # = Fields:
  # :cursor_kind ::
  #   (Symbol from _enum_cursor_kind_) The kind of entity that this completion refers to.
  #   
  #   The cursor kind will be a macro, keyword, or a declaration (one of the
  #   *Decl cursor kinds), describing the entity that the completion is
  #   referring to.
  #   
  #   \todo In the future, we would like to provide a full cursor, to allow
  #   the client to extract additional information from declaration.
  # :completion_string ::
  #   (FFI::Pointer(CompletionString)) The code-completion string that describes how to insert this
  #   code-completion result into the editing buffer.
  class CompletionResult < FFI::Struct
    layout :cursor_kind, :cursor_kind,
           :completion_string, :pointer
  end
  
  # Describes a single piece of text within a code-completion string.
  # 
  # Each "chunk" within a code-completion string (\c CXCompletionString) is
  # either a piece of text with a specific "kind" that describes how that text
  # should be interpreted by the client or is another completion string.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:completion_chunk_kind).</em>
  # 
  # === Options:
  # :optional ::
  #   A code-completion string that describes "optional" text that
  #   could be a part of the template (but is not required).
  #   
  #   The Optional chunk is the only kind of chunk that has a code-completion
  #   string for its representation, which is accessible via
  #   \c clang_getCompletionChunkCompletionString(). The code-completion string
  #   describes an additional part of the template that is completely optional.
  #   For example, optional chunks can be used to describe the placeholders for
  #   arguments that match up with defaulted function parameters, e.g. given:
  #   
  #   \code
  #   void f(int x, float y = 3.14, double z = 2.71828);
  #   \endcode
  #   
  #   The code-completion string for this function would contain:
  #     - a TypedText chunk for "f".
  #     - a LeftParen chunk for "(".
  #     - a Placeholder chunk for "int x"
  #     - an Optional chunk containing the remaining defaulted arguments, e.g.,
  #         - a Comma chunk for ","
  #         - a Placeholder chunk for "float y"
  #         - an Optional chunk containing the last defaulted argument:
  #             - a Comma chunk for ","
  #             - a Placeholder chunk for "double z"
  #     - a RightParen chunk for ")"
  #   
  #   There are many ways to handle Optional chunks. Two simple approaches are:
  #     - Completely ignore optional chunks, in which case the template for the
  #       function "f" would only include the first parameter ("int x").
  #     - Fully expand all optional chunks, in which case the template for the
  #       function "f" would have all of the parameters.
  # :typed_text ::
  #   Text that a user would be expected to type to get this
  #   code-completion result.
  #   
  #   There will be exactly one "typed text" chunk in a semantic string, which
  #   will typically provide the spelling of a keyword or the name of a
  #   declaration that could be used at the current code point. Clients are
  #   expected to filter the code-completion results based on the text in this
  #   chunk.
  # :text ::
  #   Text that should be inserted as part of a code-completion result.
  #   
  #   A "text" chunk represents text that is part of the template to be
  #   inserted into user code should this particular code-completion result
  #   be selected.
  # :placeholder ::
  #   Placeholder text that should be replaced by the user.
  #   
  #   A "placeholder" chunk marks a place where the user should insert text
  #   into the code-completion template. For example, placeholders might mark
  #   the function parameters for a function declaration, to indicate that the
  #   user should provide arguments for each of those parameters. The actual
  #   text in a placeholder is a suggestion for the text to display before
  #   the user replaces the placeholder with real code.
  # :informative ::
  #   Informative text that should be displayed but never inserted as
  #   part of the template.
  #   
  #   An "informative" chunk contains annotations that can be displayed to
  #   help the user decide whether a particular code-completion result is the
  #   right option, but which is not part of the actual template to be inserted
  #   by code completion.
  # :current_parameter ::
  #   Text that describes the current parameter when code-completion is
  #   referring to function call, message send, or template specialization.
  #   
  #   A "current parameter" chunk occurs when code-completion is providing
  #   information about a parameter corresponding to the argument at the
  #   code-completion point. For example, given a function
  #   
  #   \code
  #   int add(int x, int y);
  #   \endcode
  #   
  #   and the source code \c add(, where the code-completion point is after the
  #   "(", the code-completion string will contain a "current parameter" chunk
  #   for "int x", indicating that the current argument will initialize that
  #   parameter. After typing further, to \c add(17, (where the code-completion
  #   point is after the ","), the code-completion string will contain a
  #   "current paremeter" chunk to "int y".
  # :left_paren ::
  #   A left parenthesis ('('), used to initiate a function call or
  #   signal the beginning of a function parameter list.
  # :right_paren ::
  #   A right parenthesis (')'), used to finish a function call or
  #   signal the end of a function parameter list.
  # :left_bracket ::
  #   A left bracket ('(').
  # :right_bracket ::
  #   A right bracket (')').
  # :left_brace ::
  #   A left brace ('{').
  # :right_brace ::
  #   A right brace ('}').
  # :left_angle ::
  #   A left angle bracket ('<').
  # :right_angle ::
  #   A right angle bracket ('>').
  # :comma ::
  #   A comma separator (',').
  # :result_type ::
  #   Text that specifies the result type of a given result.
  #   
  #   This special kind of informative chunk is not meant to be inserted into
  #   the text buffer. Rather, it is meant to illustrate the type that an
  #   expression using the given completion string would have.
  # :colon ::
  #   A colon (':').
  # :semi_colon ::
  #   A semicolon (';').
  # :equal ::
  #   An '=' sign.
  # :horizontal_space ::
  #   Horizontal space (' ').
  # :vertical_space ::
  #   Vertical space ('\n'), after which it is generally a good idea to
  #   perform indentation.
  # 
  # @method _enum_completion_chunk_kind_
  # @return [Symbol]
  # @scope class
  enum :completion_chunk_kind, [
    :optional,
    :typed_text,
    :text,
    :placeholder,
    :informative,
    :current_parameter,
    :left_paren,
    :right_paren,
    :left_bracket,
    :right_bracket,
    :left_brace,
    :right_brace,
    :left_angle,
    :right_angle,
    :comma,
    :result_type,
    :colon,
    :semi_colon,
    :equal,
    :horizontal_space,
    :vertical_space
  ]
  
  # Determine the kind of a particular chunk within a completion string.
  # 
  # @method get_completion_chunk_kind(completion_string, chunk_number)
  # @param [FFI::Pointer(CompletionString)] completion_string the completion string to query.
  # @param [Integer] chunk_number the 0-based index of the chunk in the completion string.
  # @return [Symbol from _enum_completion_chunk_kind_] the kind of the chunk at the index \c chunk_number.
  # @scope class
  attach_function :get_completion_chunk_kind, :clang_getCompletionChunkKind, [:pointer, :uint], :completion_chunk_kind
  
  # Retrieve the text associated with a particular chunk within a
  # completion string.
  # 
  # @method get_completion_chunk_text(completion_string, chunk_number)
  # @param [FFI::Pointer(CompletionString)] completion_string the completion string to query.
  # @param [Integer] chunk_number the 0-based index of the chunk in the completion string.
  # @return [String] the text associated with the chunk at index \c chunk_number.
  # @scope class
  attach_function :get_completion_chunk_text, :clang_getCompletionChunkText, [:pointer, :uint], String.by_value
  
  # Retrieve the completion string associated with a particular chunk
  # within a completion string.
  # 
  # @method get_completion_chunk_completion_string(completion_string, chunk_number)
  # @param [FFI::Pointer(CompletionString)] completion_string the completion string to query.
  # @param [Integer] chunk_number the 0-based index of the chunk in the completion string.
  # @return [FFI::Pointer(CompletionString)] the completion string associated with the chunk at index
  #   \c chunk_number.
  # @scope class
  attach_function :get_completion_chunk_completion_string, :clang_getCompletionChunkCompletionString, [:pointer, :uint], :pointer
  
  # Retrieve the number of chunks in the given code-completion string.
  # 
  # @method get_num_completion_chunks(completion_string)
  # @param [FFI::Pointer(CompletionString)] completion_string 
  # @return [Integer] 
  # @scope class
  attach_function :get_num_completion_chunks, :clang_getNumCompletionChunks, [:pointer], :uint
  
  # Determine the priority of this code completion.
  # 
  # The priority of a code completion indicates how likely it is that this 
  # particular completion is the completion that the user will select. The
  # priority is selected by various internal heuristics.
  # 
  # @method get_completion_priority(completion_string)
  # @param [FFI::Pointer(CompletionString)] completion_string The completion string to query.
  # @return [Integer] The priority of this completion string. Smaller values indicate
  #   higher-priority (more likely) completions.
  # @scope class
  attach_function :get_completion_priority, :clang_getCompletionPriority, [:pointer], :uint
  
  # Determine the availability of the entity that this code-completion
  # string refers to.
  # 
  # @method get_completion_availability(completion_string)
  # @param [FFI::Pointer(CompletionString)] completion_string The completion string to query.
  # @return [Symbol from _enum_availability_kind_] The availability of the completion string.
  # @scope class
  attach_function :get_completion_availability, :clang_getCompletionAvailability, [:pointer], :availability_kind
  
  # Retrieve the number of annotations associated with the given
  # completion string.
  # 
  # @method get_completion_num_annotations(completion_string)
  # @param [FFI::Pointer(CompletionString)] completion_string the completion string to query.
  # @return [Integer] the number of annotations associated with the given completion
  #   string.
  # @scope class
  attach_function :get_completion_num_annotations, :clang_getCompletionNumAnnotations, [:pointer], :uint
  
  # Retrieve the annotation associated with the given completion string.
  # 
  # @method get_completion_annotation(completion_string, annotation_number)
  # @param [FFI::Pointer(CompletionString)] completion_string the completion string to query.
  # @param [Integer] annotation_number the 0-based index of the annotation of the
  #   completion string.
  # @return [String] annotation string associated with the completion at index
  #   \c annotation_number, or a NULL string if that annotation is not available.
  # @scope class
  attach_function :get_completion_annotation, :clang_getCompletionAnnotation, [:pointer, :uint], String.by_value
  
  # Retrieve a completion string for an arbitrary declaration or macro
  # definition cursor.
  # 
  # @method get_cursor_completion_string(cursor)
  # @param [Cursor] cursor The cursor to query.
  # @return [FFI::Pointer(CompletionString)] A non-context-sensitive completion string for declaration and macro
  #   definition cursors, or NULL for other kinds of cursors.
  # @scope class
  attach_function :get_cursor_completion_string, :clang_getCursorCompletionString, [Cursor.by_value], :pointer
  
  # Contains the results of code-completion.
  # 
  # This data structure contains the results of code completion, as
  # produced by \c clang_codeCompleteAt(). Its contents must be freed by
  # \c clang_disposeCodeCompleteResults.
  # 
  # = Fields:
  # :results ::
  #   (CompletionResult) The code-completion results.
  # :num_results ::
  #   (Integer) The number of code-completion results stored in the
  #   \c Results array.
  class CodeCompleteResults < FFI::Struct
    layout :results, CompletionResult,
           :num_results, :uint
  end
  
  # Flags that can be passed to \c clang_codeCompleteAt() to
  # modify its behavior.
  # 
  # The enumerators in this enumeration can be bitwise-OR'd together to
  # provide multiple options to \c clang_codeCompleteAt().
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:code_complete_flags).</em>
  # 
  # === Options:
  # :include_macros ::
  #   Whether to include macros within the set of code
  #   completions returned.
  # :include_code_patterns ::
  #   Whether to include code patterns for language constructs
  #   within the set of code completions, e.g., for loops.
  # 
  # @method _enum_code_complete_flags_
  # @return [Symbol]
  # @scope class
  enum :code_complete_flags, [
    :include_macros, 0x01,
    :include_code_patterns, 0x02
  ]
  
  # Bits that represent the context under which completion is occurring.
  # 
  # The enumerators in this enumeration may be bitwise-OR'd together if multiple
  # contexts are occurring simultaneously.
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:completion_context).</em>
  # 
  # === Options:
  # :completion_context_unexposed ::
  #   The context for completions is unexposed, as only Clang results
  #   should be included. (This is equivalent to having no context bits set.)
  # 
  # @method _enum_completion_context_
  # @return [Symbol]
  # @scope class
  enum :completion_context, [
    :completion_context_unexposed, 0
  ]
  
  # Returns a default set of code-completion options that can be
  # passed to\c clang_codeCompleteAt(). 
  # 
  # @method default_code_complete_options()
  # @return [Integer] 
  # @scope class
  attach_function :default_code_complete_options, :clang_defaultCodeCompleteOptions, [], :uint
  
  # Perform code completion at a given location in a translation unit.
  # 
  # This function performs code completion at a particular file, line, and
  # column within source code, providing results that suggest potential
  # code snippets based on the context of the completion. The basic model
  # for code completion is that Clang will parse a complete source file,
  # performing syntax checking up to the location where code-completion has
  # been requested. At that point, a special code-completion token is passed
  # to the parser, which recognizes this token and determines, based on the
  # current location in the C/Objective-C/C++ grammar and the state of
  # semantic analysis, what completions to provide. These completions are
  # returned via a new \c CXCodeCompleteResults structure.
  # 
  # Code completion itself is meant to be triggered by the client when the
  # user types punctuation characters or whitespace, at which point the
  # code-completion location will coincide with the cursor. For example, if \c p
  # is a pointer, code-completion might be triggered after the "-" and then
  # after the ">" in \c p->. When the code-completion location is afer the ">",
  # the completion results will provide, e.g., the members of the struct that
  # "p" points to. The client is responsible for placing the cursor at the
  # beginning of the token currently being typed, then filtering the results
  # based on the contents of the token. For example, when code-completing for
  # the expression \c p->get, the client should provide the location just after
  # the ">" (e.g., pointing at the "g") to this code-completion hook. Then, the
  # client can filter the results based on the current token text ("get"), only
  # showing those results that start with "get". The intent of this interface
  # is to separate the relatively high-latency acquisition of code-completion
  # results from the filtering of results on a per-character basis, which must
  # have a lower latency.
  # 
  # @method code_complete_at(tu, complete_filename, complete_line, complete_column, unsaved_files, num_unsaved_files, options)
  # @param [TranslationUnitImpl] tu The translation unit in which code-completion should
  #   occur. The source files for this translation unit need not be
  #   completely up-to-date (and the contents of those source files may
  #   be overridden via \p unsaved_files). Cursors referring into the
  #   translation unit may be invalidated by this invocation.
  # @param [String] complete_filename The name of the source file where code
  #   completion should be performed. This filename may be any file
  #   included in the translation unit.
  # @param [Integer] complete_line The line at which code-completion should occur.
  # @param [Integer] complete_column The column at which code-completion should occur.
  #   Note that the column should point just after the syntactic construct that
  #   initiated code completion, and not in the middle of a lexical token.
  # @param [UnsavedFile] unsaved_files the Tiles that have not yet been saved to disk
  #   but may be required for parsing or code completion, including the
  #   contents of those files.  The contents and name of these files (as
  #   specified by CXUnsavedFile) are copied when necessary, so the
  #   client only needs to guarantee their validity until the call to
  #   this function returns.
  # @param [Integer] num_unsaved_files The number of unsaved file entries in \p
  #   unsaved_files.
  # @param [Integer] options Extra options that control the behavior of code
  #   completion, expressed as a bitwise OR of the enumerators of the
  #   CXCodeComplete_Flags enumeration. The 
  #   \c clang_defaultCodeCompleteOptions() function returns a default set
  #   of code-completion options.
  # @return [CodeCompleteResults] If successful, a new \c CXCodeCompleteResults structure
  #   containing code-completion results, which should eventually be
  #   freed with \c clang_disposeCodeCompleteResults(). If code
  #   completion fails, returns NULL.
  # @scope class
  attach_function :code_complete_at, :clang_codeCompleteAt, [TranslationUnitImpl, :string, :uint, :uint, UnsavedFile, :uint, :uint], CodeCompleteResults
  
  # Sort the code-completion results in case-insensitive alphabetical 
  # order.
  # 
  # @method sort_code_completion_results(results, num_results)
  # @param [CompletionResult] results The set of results to sort.
  # @param [Integer] num_results The number of results in \p Results.
  # @return [nil] 
  # @scope class
  attach_function :sort_code_completion_results, :clang_sortCodeCompletionResults, [CompletionResult, :uint], :void
  
  # Free the given set of code-completion results.
  # 
  # @method dispose_code_complete_results(results)
  # @param [CodeCompleteResults] results 
  # @return [nil] 
  # @scope class
  attach_function :dispose_code_complete_results, :clang_disposeCodeCompleteResults, [CodeCompleteResults], :void
  
  # Determine the number of diagnostics produced prior to the
  # location where code completion was performed.
  # 
  # @method code_complete_get_num_diagnostics(results)
  # @param [CodeCompleteResults] results 
  # @return [Integer] 
  # @scope class
  attach_function :code_complete_get_num_diagnostics, :clang_codeCompleteGetNumDiagnostics, [CodeCompleteResults], :uint
  
  # Retrieve a diagnostic associated with the given code completion.
  # 
  # Result: 
  # the code completion results to query.
  # 
  # @method code_complete_get_diagnostic(results, index)
  # @param [CodeCompleteResults] results 
  # @param [Integer] index the zero-based diagnostic number to retrieve.
  # @return [FFI::Pointer(Diagnostic)] the requested diagnostic. This diagnostic must be freed
  #   via a call to \c clang_disposeDiagnostic().
  # @scope class
  attach_function :code_complete_get_diagnostic, :clang_codeCompleteGetDiagnostic, [CodeCompleteResults, :uint], :pointer
  
  # Determines what compeltions are appropriate for the context
  # the given code completion.
  # 
  # @method code_complete_get_contexts(results)
  # @param [CodeCompleteResults] results the code completion results to query
  # @return [Integer] the kinds of completions that are appropriate for use
  #   along with the given code completion results.
  # @scope class
  attach_function :code_complete_get_contexts, :clang_codeCompleteGetContexts, [CodeCompleteResults], :ulong_long
  
  # Returns the cursor kind for the container for the current code
  # completion context. The container is only guaranteed to be set for
  # contexts where a container exists (i.e. member accesses or Objective-C
  # message sends); if there is not a container, this function will return
  # CXCursor_InvalidCode.
  # 
  # @method code_complete_get_container_kind(results, is_incomplete)
  # @param [CodeCompleteResults] results the code completion results to query
  # @param [FFI::Pointer(*UInt)] is_incomplete on return, this value will be false if Clang has complete
  #   information about the container. If Clang does not have complete
  #   information, this value will be true.
  # @return [Symbol from _enum_cursor_kind_] the container kind, or CXCursor_InvalidCode if there is not a
  #   container
  # @scope class
  attach_function :code_complete_get_container_kind, :clang_codeCompleteGetContainerKind, [CodeCompleteResults, :pointer], :cursor_kind
  
  # Returns the USR for the container for the current code completion
  # context. If there is not a container for the current context, this
  # function will return the empty string.
  # 
  # @method code_complete_get_container_usr(results)
  # @param [CodeCompleteResults] results the code completion results to query
  # @return [String] the USR for the container
  # @scope class
  attach_function :code_complete_get_container_usr, :clang_codeCompleteGetContainerUSR, [CodeCompleteResults], String.by_value
  
  # Returns the currently-entered selector for an Objective-C message
  # send, formatted like "initWithFoo:bar:". Only guaranteed to return a
  # non-empty string for CXCompletionContext_ObjCInstanceMessage and
  # CXCompletionContext_ObjCClassMessage.
  # 
  # @method code_complete_get_obj_c_selector(results)
  # @param [CodeCompleteResults] results the code completion results to query
  # @return [String] the selector (or partial selector) that has been entered thus far
  #   for an Objective-C message send.
  # @scope class
  attach_function :code_complete_get_obj_c_selector, :clang_codeCompleteGetObjCSelector, [CodeCompleteResults], String.by_value
  
  # Return a version string, suitable for showing to a user, but not
  #        intended to be parsed (the format is not guaranteed to be stable).
  # 
  # @method get_clang_version()
  # @return [String] 
  # @scope class
  attach_function :get_clang_version, :clang_getClangVersion, [], String.by_value
  
  # Enable/disable crash recovery.
  # 
  # Flag: 
  # to indicate if crash recovery is enabled.  A non-zero value
  #        enables crash recovery, while 0 disables it.
  # 
  # @method toggle_crash_recovery(is_enabled)
  # @param [Integer] is_enabled 
  # @return [nil] 
  # @scope class
  attach_function :toggle_crash_recovery, :clang_toggleCrashRecovery, [:uint], :void
  
  # Visitor invoked for each file in a translation unit
  #        (used with clang_getInclusions()).
  # 
  # This visitor function will be invoked by clang_getInclusions() for each
  # file included (either at the top-level or by #include directives) within
  # a translation unit.  The first argument is the file being included, and
  # the second and third arguments provide the inclusion stack.  The
  # array is sorted in order of immediate inclusion.  For example,
  # the first element refers to the location that included 'included_file'.
  # 
  # <em>This entry is only for documentation and no real method.</em>
  # 
  # @method _callback_inclusion_visitor_(inclusion_stack, include_len, client_data)
  # @param [SourceLocation] inclusion_stack 
  # @param [Integer] include_len 
  # @param [FFI::Pointer(ClientData)] client_data 
  # @return [FFI::Pointer(File)] 
  # @scope class
  callback :inclusion_visitor, [SourceLocation, :uint, :pointer], :pointer
  
  # Visit the set of preprocessor inclusions in a translation unit.
  #   The visitor function is called with the provided data for every included
  #   file.  This does not include headers included by the PCH file (unless one
  #   is inspecting the inclusions in the PCH file itself).
  # 
  # @method get_inclusions(tu, visitor, client_data)
  # @param [TranslationUnitImpl] tu 
  # @param [Proc(_callback_inclusion_visitor_)] visitor 
  # @param [FFI::Pointer(ClientData)] client_data 
  # @return [nil] 
  # @scope class
  attach_function :get_inclusions, :clang_getInclusions, [TranslationUnitImpl, :inclusion_visitor, :pointer], :void
  
  # Retrieve a remapping.
  # 
  # @method get_remappings(path)
  # @param [String] path the path that contains metadata about remappings.
  # @return [FFI::Pointer(Remapping)] the requested remapping. This remapping must be freed
  #   via a call to \c clang_remap_dispose(). Can return NULL if an error occurred.
  # @scope class
  attach_function :get_remappings, :clang_getRemappings, [:string], :pointer
  
  # Determine the number of remappings.
  # 
  # @method remap_get_num_files(remapping)
  # @param [FFI::Pointer(Remapping)] remapping 
  # @return [Integer] 
  # @scope class
  attach_function :remap_get_num_files, :clang_remap_getNumFiles, [:pointer], :uint
  
  # Get the original and the associated filename from the remapping.
  # 
  # @method remap_get_filenames(remapping, index, original, transformed)
  # @param [FFI::Pointer(Remapping)] remapping 
  # @param [Integer] index 
  # @param [String] original If non-NULL, will be set to the original filename.
  # @param [String] transformed If non-NULL, will be set to the filename that the original
  #   is associated with.
  # @return [nil] 
  # @scope class
  attach_function :remap_get_filenames, :clang_remap_getFilenames, [:pointer, :uint, String, String], :void
  
  # Dispose the remapping.
  # 
  # @method remap_dispose(remapping)
  # @param [FFI::Pointer(Remapping)] remapping 
  # @return [nil] 
  # @scope class
  attach_function :remap_dispose, :clang_remap_dispose, [:pointer], :void
  
  # \defgroup CINDEX_HIGH Higher level API functions
  # 
  # @{
  # 
  # <em>This entry is only for documentation and no real method. The FFI::Enum can be accessed via #enum_type(:visitor_result).</em>
  # 
  # === Options:
  # :break ::
  #   
  # :continue ::
  #   
  # 
  # @method _enum_visitor_result_
  # @return [Symbol]
  # @scope class
  enum :visitor_result, [
    :break,
    :continue
  ]
  
  # \defgroup CINDEX_HIGH Higher level API functions
  # 
  # @{
  # 
  # = Fields:
  # :context ::
  #   (FFI::Pointer(*Void)) 
  # :visit ::
  #   (FFI::Pointer(*)) 
  class CursorAndRangeVisitor < FFI::Struct
    layout :context, :pointer,
           :visit, :pointer
  end
  
  # Find references of a declaration in a specific file.
  # 
  # @method find_references_in_file(cursor, file, visitor)
  # @param [Cursor] cursor pointing to a declaration or a reference of one.
  # @param [FFI::Pointer(File)] file to search for references.
  # @param [CursorAndRangeVisitor] visitor callback that will receive pairs of CXCursor/CXSourceRange for
  #   each reference found.
  #   The CXSourceRange will point inside the file; if the reference is inside
  #   a macro (and not a macro argument) the CXSourceRange will be invalid.
  # @return [nil] 
  # @scope class
  attach_function :find_references_in_file, :clang_findReferencesInFile, [Cursor.by_value, :pointer, CursorAndRangeVisitor.by_value], :void
  
end
end
