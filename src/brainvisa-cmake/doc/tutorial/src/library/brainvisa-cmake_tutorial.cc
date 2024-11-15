
#include <brainvisa-cmake_tutorial/brainvisa-cmake_tutorial.h>
#include <sstream>

using namespace std;

namespace brainvisacmake_tutorial {

Date::Date( int d, int m, int y ) : day( d ), month( m ), year( y ) {}
string Date::str()
{
  stringstream o;
  o << day << "/" << month << "/" << year;
  return o.str();
}

} // namespace brainvisa-cmake_tutorial
