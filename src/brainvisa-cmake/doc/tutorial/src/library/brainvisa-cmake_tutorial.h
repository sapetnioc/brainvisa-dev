
#ifndef BRAINVISACMAKE_TUTORIAL_H
#define BRAINVISACMAKE_TUTORIAL_H

#include <string>

namespace brainvisacmake_tutorial {

class Date
{
public:

  Date( int day, int month, int year );
  std::string str();

  int day, month, year;
};

} // namespace brainvisacmake_tutorial
#endif // BRAINVISACMAKE_TUTORIAL_H
