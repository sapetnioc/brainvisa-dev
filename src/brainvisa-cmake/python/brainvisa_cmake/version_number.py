# -*- coding: utf-8 -*-
version_separator = '.'

class VersionFormat( object ):
    ''' VersionFormat is a class that describes version formats.
        A version format is decribed using a separator and a length.
        i.e.: version 1.2.3 has a length of 3 and uses '.' as a separator.
    '''
    def __new__( cls, separator, length = None ):
        '''
            The __new__ method of :py:class:`VersionFormat` class instanciates
            a single instance of the format based on .
        '''
        if '_version_format_instance' not in cls.__dict__:
            cls._version_format_instance = dict()
            
        k = (separator, length)
        if k not in cls._version_format_instance:
            cls._version_format_instance[k] = super(
                                                  VersionFormat,
                                                  cls
                                              ).__new__( cls )
            version_format_init = getattr( cls._version_format_instance[k],
                                           '__version_format_init__',
                                           None )
                                        
            if version_format_init is not None:
                version_format_init( separator, length )
        
        return cls._version_format_instance[k]
        
    def __version_format_init__( self, separator, length = None ):
        ''' Constructor of VersionFormat.
            
            @type separator: string
            @param separator: The separator used for version
            
            @type length: int
            @param length: The length to use for version
        '''
        super( VersionFormat, self ).__init__()
        
        self._version_sep = separator
        self._version_len = length
        
    def separator( self ):
        ''' Separator used by the VersionFormat.
        
            @type version: string
            @param version: The version format separator.
                            Basically a version separator is a single character.
                            In most cases the '.' character is used.
        '''
        return self._version_sep
        
    def length( self ):
        ''' Length used by the VersionFormat.
        
            @type version: string
            @param version: The version format length.
                            Basically the version length is the number of
                            numbers in the version format.
                            The version 1.2.13 has a length of 3.
                            In many cases, a version is described with 3 numbers
                            - Major number. It is the left most number. It
                              corresponds to import changes that lead to
                              compatibility breaks.
                            - Minor number. It is the second left most number.
                              It corresponds to minor changes and functionnality
                              addition.
                            - Micro number. It is the third number. It is often
                              the bug fix version.
        '''
        return self._version_len


version_format_unconstrained = VersionFormat(
                                   separator = version_separator,
                                   length = None
                               )
                               
version_format_release = VersionFormat(
                              separator = version_separator,
                              length = 3
                          )
                          
version_format_short = VersionFormat(
                          separator = version_separator,
                          length = 2
                       )

def version_to_list(version, separator=version_separator):
    """ Converts a version string to a list of integers
    """
    version = version.replace('"', '')
    version = ''.join([x for x in version if x in '0123456789.'])
    return [int(v) for v in version.split(separator)]
    
def list_to_version( version_list, separator = version_separator ):
    """ Converts a list of integers to a version string
    """
    return separator.join([str(v) for v in version_list])
    
class VersionNumber( object ):
    ''' VersionNumber is a class that manages version numbers.
    '''
    
    def __init__( self, version, format = None ):
        ''' Constructor of VersionNumber.
        
            @type version: string or VersionNumber or list or tuple
            @param version: The version
            
            @type format: VersionFormat
            @param format: The format used to parse and display version
            
        '''
        super( VersionNumber, self ).__init__()
        
        if isinstance( version, VersionNumber ):
            
            if format is None:
                self._format = version._format
                
            else:
                self._format = format
                
            self._version_numbers = list( version._version_numbers )
        
        else:
            if format is None:
                self._format = version_format_unconstrained
                
            else:
                self._format = format
            
            if isinstance( version, str ):
                self._version_numbers = version_to_list(
                                            version,
                                            separator = self._format.separator()
                                        )
            
            elif isinstance( version, (list, tuple) ):
                self._version_numbers = list( version )
                
            elif isinstance( version, int ):
                self._version_numbers = [ version ]
                
            elif version is None:
                self._version_numbers = [ 0 ]
                
            else:
                raise RuntimeError( 'VersionNumber constructor: Unsupported'
                                    ' version type \'' \
                                    + type( version ).__name__ + '\'.' )
                                    
        if not self._format.length() is None:
            self.resize( self._format.length() )
    
    def __eq__( self, other ):
        ''' VersionNumber equal operator.
        
            @type other: VersionNumber
            @param other: The version to compare to.
            
            @rtype: boolean
            @return: True if current version is equal to other version. False
                    otherwise.
        '''
        if not isinstance(other, VersionNumber):
            # Try to convert to VersionNumber instance
            other = VersionNumber(
                        other,
                        format = self._format
                    )
            
        return self._version_numbers.__eq__( other._version_numbers )
    
    def __ne__( self, other ):
        ''' VersionNumber not equal operator.
        
            @type other: VersionNumber
            @param other: The version to compare to.
            
            @rtype: boolean
            @return: True if current version is not equal to other version.
                    False otherwise.
        '''
        if not isinstance(other, VersionNumber):
            # Try to convert to VersionNumber instance
            other = VersionNumber(
                        other,
                        format = self._format
                    )
            
        return self._version_numbers.__ne__( other._version_numbers )
        
    def __lt__( self, other ):
        ''' VersionNumber lower than operator.
        
            @type other: VersionNumber
            @param other: The version to compare to.
            
            @rtype: boolean
            @return: True if current version is lower than other version. False
                    otherwise.
        '''
        if not isinstance(other, VersionNumber):
            # Try to convert to VersionNumber instance
            other = VersionNumber(
                        other,
                        format = self._format
                    )
            
        return self._version_numbers.__lt__( other._version_numbers )
        
    def __le__( self, other ):
        ''' VersionNumber lower than or equal operator.
        
            @type other: VersionNumber
            @param other: The version to compare to.
            
            @rtype: boolean
            @return: True if current version is lower or equal to other version.
                    False otherwise.
        '''
        if not isinstance(other, VersionNumber):
            # Try to convert to VersionNumber instance
            other = VersionNumber(
                        other,
                        format = self._format
                    )
            
        return self._version_numbers.__le__( other._version_numbers )
        
    def __gt__( self, other ):
        ''' VersionNumber greater than operator.
        
            @type other: VersionNumber
            @param other: The version to compare to.
            
            @rtype: boolean
            @return: True if current version is greater than other version.
                    False otherwise.
        '''
        if not isinstance(other, VersionNumber):
            # Try to convert to VersionNumber instance
            other = VersionNumber(
                        other,
                        format = self._format
                    )
            
        return self._version_numbers.__gt__( other._version_numbers )
        
    def __ge__( self, other ):
        ''' VersionNumber greater than or equal operator.
        
            @type other: VersionNumber
            @param other: The version to compare to.
            
            @rtype: boolean
            @return: True if current version is greater than or equal to other 
                    version. False otherwise.
        '''
        if not isinstance(other, VersionNumber):
            # Try to convert to VersionNumber instance
            other = VersionNumber(
                        other,
                        format = self._format
                    )
            
        return self._version_numbers.__ge__( other._version_numbers )
        
    def __str__( self ):
        ''' VersionNumber string conversion operator.
            
            @rtype: string
            @return: The version string.
        '''
        return list_to_version(
                   self,
                   separator = self._format.separator()
               )
      
    def __add__( self, other ):
        ''' VersionNumber addition operator.
        
            @type other: VersionNumber
            @param other: The object to add.
            
            @rtype: VersionNumber
            @return: The resulting VersionNumber.
        '''
        if isinstance( other, int ):
            # Add the value to the right most version component
            r = VersionNumber(self)
            r._version_numbers[ -1 ] += int(other)
            return r
            
        elif isinstance( other, VersionNumber ):
            maxlen = max( len(self), len(other) )
            v1_numbers = self._version_numbers + [0] * (maxlen - len(self))
            v2_numbers = other._version_numbers + [0] * (maxlen - len(other))
            
            return VersionNumber(
                       [ a + b for a, b in zip( v1_numbers, v2_numbers ) ],
                       format = self._format
                   )
            
        else:
            return self + VersionNumber(
                              other,
                              format = self._format
                          )
            
    def __sub__( self, other ):
        ''' VersionNumber substraction operator.
        
            @type other: VersionNumber
            @param other: The object to substract.
            
            @rtype: VersionNumber
            @return: The resulting VersionNumber.
        '''
        if isinstance( other, int ):
            # Add the value to the right most version component
            r = VersionNumber( self )
            r._version_numbers[ -1 ] -= int(other)
            return r
            
        elif isinstance( other, VersionNumber ):
            maxlen = max( len(self), len(other) )
            v1_numbers = self._version_numbers + [0] * (maxlen - len(self))
            v2_numbers = other._version_numbers + [0] * (maxlen - len(other))
            
            return VersionNumber(
                       [ a - b for a, b in zip( v1_numbers, v2_numbers ) ],
                       format = self._format
                   )
            
        else:
            return self - VersionNumber(
                              other,
                              format = self._format
                          )
            
    def __iter__( self ):
        ''' VersionNumber iter operator.
            
            @rtype: VersionNumber
            @return: The iterator to the VersionNumber.
        '''
        return iter(self._version_numbers)
        
    def __len__( self ):
        ''' VersionNumber length operator.
        
            @rtype: int
            @return: The size of VersionNumber.
        '''
        return len(self._version_numbers)
        
    def __getitem__( self, key ):
        ''' VersionNumber getitem operator.
        
            @type key: Slice
            @param key: The slice to get.
            
            @rtype: VersionNumber
            @return: The VersionNumber for the slice.
        '''
        return VersionNumber(
                   self._version_numbers.__getitem__( key ),
                   format = VersionFormat(
                        separator = self._format.separator()
                   )
               )
        
    def __setitem__( self, key, value ):
        ''' VersionNumber setitem operator.
        
            @type key: Slice
            @param key: The slice to set.
            
            @rtype: VersionNumber
            @return: The current VersionNumber.
        '''
        if not isinstance( value, VersionNumber ):
            # Create unconstrained version number
            value = VersionNumber( value )
            
        if isinstance( key, slice ):
            self._version_numbers.__setitem__( key, value._version_numbers )
        
        elif isinstance( key, int ) \
            and len( value ) == 1:
            self._version_numbers.__setitem__( key, value._version_numbers[0] )

        if not self._format.length() is None:
            # Resize internal version numbers to keep coherent size
            self.resize( length = self._format.length() )
        
    def __delitem__( self, key ):
        ''' VersionNumber delitem operator.
        
            @type key: Slice
            @param key: The slice to delete.
        '''
        self._version_numbers.__delitem__( key )
        
        if not self._format.length() is None:
            # Resize internal version numbers to keep coherent size
            self.resize( length = self._format.length() )
        
    def extend( self, value ):
        ''' Extend VersionNumber using a given value.
        
            @type value: VersionNumber
            @param value: The value to use to extend version.
        '''
        
        if not isinstance( value, VersionNumber ):
            # Create unconstrained version number
            value = VersionNumber( value )

        if not self._format.length() is None:
            # Update internal version format to keep coherent size
            # I am not sure that it is coherent to extend a constrained
            # length version
            self.update_format( length = self._format.length() + len(value) )
                     
        self._version_numbers.extend( value._version_numbers )

        
    def resize( self, length, value = 0 ):
        ''' resize a VersionNumber using a given length.
        
            @type length: int
            @param value: The length of the version.
        '''
        
        if not self._format.length() is None:
            # Update internal version format to keep coherent size
            # I am not sure that it is coherent to resize a constrained
            # length version
            self.update_format( length = length )
                       
        if length > len( self._version_numbers ) :
            self._version_numbers += [ value ] \
                                   * ( length - len( self._version_numbers ) )
                                
        elif length < len( self._version_numbers ) :
            self._version_numbers = self._version_numbers[ :length ]
        
        return self

    def increment( self, position = -1, increment = 1 ):
        """ Increments a version number at a specified position.
            By default, the right most digit is incremented.
            i.e.: 1.2.3 => 1.2.4
                  1.2 => 1.3
            When a position is given, the version digit at the specified
            position is incremented and right most digits are reset to 0.
            i.e.: position 1 : 1.2.3 => 1.3.0
                  position 0 : 1.2.3 => 2.0.0
        
            @type position: string
            @param position: The position to increment in version.
            
            @rtype: VersionNumber
            @return: The incremented version.
        """
        if position >= len(self) :
            raise RuntimeError( 'Unable to increment version:', str(self),
                                'at position:', position,
                                '. Position must be <', len(self) )
    
        self[ position ] += increment
        
        if position < 0:
            position = len(self) + position
        
        self[ position + 1: ] = [ 0 ] * (len(self) - position - 1)

        return self
    
    def update_format( self, separator = None, length = None ):
        '''
            Update version format if separator or length changed.
            
            @type separator: string
            @param separatot: The separator of the version format to use.
                              [default: None]
            
            @type length: int
            @param length: The length of the version format to use.
                           [default: None]
        '''
        if not separator is None:
            separator_new = separator
        else:
            separator_new = self._format.separator()
            
        #if not length is None:
            #length_new = length
        #else:
            #length_new = self._format.length()
        
        if ((separator_new != self._format.separator()) or \
            (length != self._format.length()) ):
            # Update internal version format
            self._format = VersionFormat(
                                separator = separator_new,
                                length = length
                            )
