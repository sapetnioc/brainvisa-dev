# Find Docbook xsl stylesheets and dtd
# The following variables are set:
#
#  DOCBOOK_FOUND - Was docbook found
#  DOCBOOK_XSL_STYLESHEET  - path to the docbook xsl stylesheets
#  DOCBOOK_DTD  - path to the docbook dtd

if( DOCBOOK_XSL_STYLESHEET AND DOCBOOK_DTD)

  set( DOCBOOK_FOUND true )

else()
  
  # First we only search in environment variable
  find_file(xsl NAMES catalog.xml
  PATHS ENV XSL_STYLESHEET
  NO_DEFAULT_PATH )
  
  if( NOT xsl )
    # Then we do a global search
    find_file(xsl NAMES catalog.xml
    PATH_SUFFIXES docbook-xsl share/docbook-xsl share/xml/docbook/stylesheet/docbook-xsl)
  endif()
  
  if(xsl)
    get_filename_component(DOCBOOK_XSL_STYLESHEET ${xsl} PATH CACHE)
  endif()
  unset(xsl CACHE)
  
  find_file(dtd NAMES docbookx.dtd
    PATHS ENV DTD
    PATH_SUFFIXES share/xml/docbook/schema/dtd/4.4 share/sgml/docbook/xml-dtd-4.4)
  if(dtd)
    get_filename_component(DOCBOOK_DTD ${dtd} PATH CACHE)
  endif()
  unset(dtd CACHE)
  
  if( DOCBOOK_XSL_STYLESHEET AND DOCBOOK_DTD )
    set( DOCBOOK_FOUND true )

    if( NOT Docbook_FIND_QUIETLY )
      message( STATUS "Found docbook xsl stylesheets: \"${DOCBOOK_XSL_STYLESHEET}\" and dtd: ${DOCBOOK_DTD}" )
    endif()
  
  else()
    set( DOCBOOK_FOUND false )
    
    if( Docbook_FIND_REQUIRED )
      message( FATAL_ERROR "Docbook not found" )
    else()
      if( NOT Docbook_FIND_QUIETLY )
        message( STATUS "Docbook not found" )
      endif()
    endif()
    
  endif()

endif()
