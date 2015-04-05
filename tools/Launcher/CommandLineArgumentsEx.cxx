/*============================================================================
  KWSys - Kitware System Library
  Copyright 2000-2009 Kitware, Inc., Insight Software Consortium

  Distributed under the OSI-approved BSD License (the "License");
  see accompanying file Copyright.txt for details.

  This software is distributed WITHOUT ANY WARRANTY; without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the License for more information.
============================================================================*/
#define _CRT_SECURE_NO_WARNINGS
#include "CommandLineArgumentsEx.hpp"

#include <vector>
#include <map>
#include <set>
#include <sstream>
#include <iostream>
#include <string>



#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _MSC_VER
# pragma warning (disable: 4786)
#endif


namespace Force
{

//----------------------------------------------------------------------------
//============================================================================
struct CommandLineArgumentsCallbackStructure
{
  const wchar_t* Argument;
  int ArgumentType;
  CommandLineArguments::CallbackType Callback;
  void* CallData;
  void* Variable;
  int VariableType;
  const wchar_t* Help;
};

class CommandLineArgumentsVectorOfStrings :
  public std::vector<std::wstring> {};
class CommandLineArgumentsSetOfStrings :
  public std::set<std::wstring> {};
class CommandLineArgumentsMapOfStrucs :
  public std::map<std::wstring,
    CommandLineArgumentsCallbackStructure> {};

class CommandLineArgumentsInternal
{
public:
  CommandLineArgumentsInternal()
    {
    this->UnknownArgumentCallback = 0;
    this->ClientData = 0;
    this->LastArgument = 0;
    }

  typedef CommandLineArgumentsVectorOfStrings VectorOfStrings;
  typedef CommandLineArgumentsMapOfStrucs CallbacksMap;
  typedef std::wstring String;
  typedef CommandLineArgumentsSetOfStrings SetOfStrings;

  VectorOfStrings Argv;
  String Argv0;
  CallbacksMap Callbacks;

  CommandLineArguments::ErrorCallbackType UnknownArgumentCallback;
  void*             ClientData;

  VectorOfStrings::size_type LastArgument;

  VectorOfStrings UnusedArguments;
};
//============================================================================
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
CommandLineArguments::CommandLineArguments()
{
  this->Internals = new CommandLineArguments::Internal;
  this->Help = L"";
  this->LineLength = 80;
  this->StoreUnusedArgumentsFlag = false;
}

//----------------------------------------------------------------------------
CommandLineArguments::~CommandLineArguments()
{
  delete this->Internals;
}

//----------------------------------------------------------------------------
void CommandLineArguments::Initialize(int argc, const wchar_t* const argv[])
{
  int cc;

  this->Initialize();
  this->Internals->Argv0 = argv[0];
  for ( cc = 1; cc < argc; cc ++ )
    {
    this->ProcessArgument(argv[cc]);
    }
}

//----------------------------------------------------------------------------
void CommandLineArguments::Initialize(int argc, wchar_t* argv[])
{
  this->Initialize(argc, static_cast<const wchar_t* const*>(argv));
}

//----------------------------------------------------------------------------
void CommandLineArguments::Initialize()
{
  this->Internals->Argv.clear();
  this->Internals->LastArgument = 0;
}

//----------------------------------------------------------------------------
void CommandLineArguments::ProcessArgument(const wchar_t* arg)
{
  this->Internals->Argv.push_back(arg);
}

//----------------------------------------------------------------------------
bool CommandLineArguments::GetMatchedArguments(
  std::vector<std::wstring>* matches,
  const std::wstring& arg)
{
  matches->clear();
  CommandLineArguments::Internal::CallbacksMap::iterator it;

  // Does the argument match to any we know about?
  for ( it = this->Internals->Callbacks.begin();
    it != this->Internals->Callbacks.end();
    it ++ )
    {
    const CommandLineArguments::Internal::String& parg = it->first;
    CommandLineArgumentsCallbackStructure *cs = &it->second;
    if (cs->ArgumentType == CommandLineArguments::NO_ARGUMENT ||
      cs->ArgumentType == CommandLineArguments::SPACE_ARGUMENT)
      {
      if ( arg == parg )
        {
        matches->push_back(parg);
        }
      }
    else if ( arg.find( parg ) == 0 )
      {
      matches->push_back(parg);
      }
    }
  return !matches->empty();
}

//----------------------------------------------------------------------------
int CommandLineArguments::Parse()
{
  std::vector<std::wstring>::size_type cc;
  std::vector<std::wstring> matches;
  if ( this->StoreUnusedArgumentsFlag )
    {
    this->Internals->UnusedArguments.clear();
    }
  for ( cc = 0; cc < this->Internals->Argv.size(); cc ++ )
    {
    const std::wstring& arg = this->Internals->Argv[cc];
    this->Internals->LastArgument = cc;
    if ( this->GetMatchedArguments(&matches, arg) )
      {
      // Ok, we found one or more arguments that match what user specified.
      // Let's find the longest one.
      CommandLineArguments::Internal::VectorOfStrings::size_type kk;
      CommandLineArguments::Internal::VectorOfStrings::size_type maxidx = 0;
      CommandLineArguments::Internal::String::size_type maxlen = 0;
      for ( kk = 0; kk < matches.size(); kk ++ )
        {
        if ( matches[kk].size() > maxlen )
          {
          maxlen = matches[kk].size();
          maxidx = kk;
          }
        }
      // So, the longest one is probably the right one. Now see if it has any
      // additional value
      CommandLineArgumentsCallbackStructure *cs
        = &this->Internals->Callbacks[matches[maxidx]];
      const std::wstring& sarg = matches[maxidx];
      if ( cs->Argument != sarg )
        {
        abort();
        }
      switch ( cs->ArgumentType )
        {
      case NO_ARGUMENT:
        // No value
        if ( !this->PopulateVariable(cs, 0) )
          {
          return 0;
          }
        break;
      case SPACE_ARGUMENT:
        if ( cc == this->Internals->Argv.size()-1 )
          {
          this->Internals->LastArgument --;
          return 0;
          }
        // Value is the next argument
        if ( !this->PopulateVariable(cs, this->Internals->Argv[cc+1].c_str()) )
          {
          return 0;
          }
        cc ++;
        break;
      case EQUAL_ARGUMENT:
        if ( arg.size() == sarg.size() || arg.at(sarg.size()) != '=' )
          {
          this->Internals->LastArgument --;
          return 0;
          }
        // Value is everythng followed the '=' sign
        if ( !this->PopulateVariable(cs, arg.c_str() + sarg.size() + 1) )
          {
          return 0;
          }
        break;
      case CONCAT_ARGUMENT:
        // Value is whatever follows the argument
        if ( !this->PopulateVariable(cs, arg.c_str() + sarg.size()) )
          {
          return 0;
          }
        break;
      case MULTI_ARGUMENT:
        // Suck in all the rest of the arguments
        for (cc++; cc < this->Internals->Argv.size(); ++ cc )
          {
          const std::wstring& marg = this->Internals->Argv[cc];
          if ( this->GetMatchedArguments(&matches, marg) )
            {
              break;
            }
          if ( !this->PopulateVariable(cs, marg.c_str()) )
            {
            return 0;
            }
          }
        if ( cc != this->Internals->Argv.size() )
          {
          cc--;
          continue;
          }
        break;
      default:
        std::wcerr << L"Got unknown argument type: \"" << cs->ArgumentType << L"\"" << std::endl;
        this->Internals->LastArgument --;
        return 0;
        }
      }
    else
      {
      // Handle unknown arguments
      if ( this->Internals->UnknownArgumentCallback )
        {
        if ( !this->Internals->UnknownArgumentCallback(arg.c_str(),
            this->Internals->ClientData) )
          {
          this->Internals->LastArgument --;
          return 0;
          }
        return 1;
        }
      else if ( this->StoreUnusedArgumentsFlag )
        {
        this->Internals->UnusedArguments.push_back(arg);
        }
      else
        {
        std::wcerr << L"Got unknown argument: \"" << arg << L"\"" << std::endl;
        this->Internals->LastArgument --;
        return 0;
        }
      }
    }
  return 1;
}

//----------------------------------------------------------------------------
void CommandLineArguments::GetRemainingArguments(int* argc, wchar_t*** argv)
{
  CommandLineArguments::Internal::VectorOfStrings::size_type size
    = this->Internals->Argv.size() - this->Internals->LastArgument + 1;
  CommandLineArguments::Internal::VectorOfStrings::size_type cc;

  // Copy Argv0 as the first argument
  wchar_t** args = new wchar_t*[ size ];
  args[0] = new wchar_t[ this->Internals->Argv0.size() + 1 ];
  wcscpy_s(args[0],this->Internals->Argv0.size(), this->Internals->Argv0.c_str());
  int cnt = 1;

  // Copy everything after the LastArgument, since that was not parsed.
  for ( cc = this->Internals->LastArgument+1;
    cc < this->Internals->Argv.size(); cc ++ )
    {
    args[cnt] = new wchar_t[ this->Internals->Argv[cc].size() + 1];
    wcscpy_s(args[cnt], this->Internals->Argv[cc].size(),this->Internals->Argv[cc].c_str());
    cnt ++;
    }
  *argc = cnt;
  *argv = args;
}

//----------------------------------------------------------------------------
void CommandLineArguments::GetUnusedArguments(int* argc, wchar_t*** argv)
{
  CommandLineArguments::Internal::VectorOfStrings::size_type size
    = this->Internals->UnusedArguments.size() + 1;
  CommandLineArguments::Internal::VectorOfStrings::size_type cc;

  // Copy Argv0 as the first argument
  wchar_t** args = new wchar_t*[ size ];
  args[0] = new wchar_t[ this->Internals->Argv0.size() + 1 ];
  wcscpy_s(args[0],this->Internals->Argv0.size(), this->Internals->Argv0.c_str());
  int cnt = 1;

  // Copy everything after the LastArgument, since that was not parsed.
  for ( cc = 0;
    cc < this->Internals->UnusedArguments.size(); cc ++ )
    {
    std::wstring &str = this->Internals->UnusedArguments[cc];
    args[cnt] = new wchar_t[ str.size() + 1];
    wcscpy_s(args[cnt],str.size(), str.c_str());
    cnt ++;
    }
  *argc = cnt;
  *argv = args;
}

//----------------------------------------------------------------------------
void CommandLineArguments::DeleteRemainingArguments(int argc, wchar_t*** argv)
{
  int cc;
  for ( cc = 0; cc < argc; ++ cc )
    {
    delete [] (*argv)[cc];
    }
  delete [] *argv;
}

//----------------------------------------------------------------------------
void CommandLineArguments::AddCallback(const wchar_t* argument, ArgumentTypeEnum type,
  CallbackType callback, void* call_data, const wchar_t* help)
{
  CommandLineArgumentsCallbackStructure s;
  s.Argument     = argument;
  s.ArgumentType = type;
  s.Callback     = callback;
  s.CallData     = call_data;
  s.VariableType = CommandLineArguments::NO_VARIABLE_TYPE;
  s.Variable     = 0;
  s.Help         = help;

  this->Internals->Callbacks[argument] = s;
  this->GenerateHelp();
}

//----------------------------------------------------------------------------
void CommandLineArguments::AddArgument(const wchar_t* argument, ArgumentTypeEnum type,
  VariableTypeEnum vtype, void* variable, const wchar_t* help)
{
  CommandLineArgumentsCallbackStructure s;
  s.Argument     = argument;
  s.ArgumentType = type;
  s.Callback     = 0;
  s.CallData     = 0;
  s.VariableType = vtype;
  s.Variable     = variable;
  s.Help         = help;

  this->Internals->Callbacks[argument] = s;
  this->GenerateHelp();
}

//----------------------------------------------------------------------------
#define CommandLineArgumentsAddArgumentMacro(type, ctype) \
  void CommandLineArguments::AddArgument(const wchar_t* argument, ArgumentTypeEnum type, \
    ctype* variable, const wchar_t* help) \
  { \
    this->AddArgument(argument, type, CommandLineArguments::type##_TYPE, variable, help); \
  }

CommandLineArgumentsAddArgumentMacro(BOOL,       bool)
CommandLineArgumentsAddArgumentMacro(INT,        int)
CommandLineArgumentsAddArgumentMacro(DOUBLE,     double)
CommandLineArgumentsAddArgumentMacro(STRING,     wchar_t*)
CommandLineArgumentsAddArgumentMacro(STL_STRING, std::wstring)

CommandLineArgumentsAddArgumentMacro(VECTOR_BOOL,       std::vector<bool>)
CommandLineArgumentsAddArgumentMacro(VECTOR_INT,        std::vector<int>)
CommandLineArgumentsAddArgumentMacro(VECTOR_DOUBLE,     std::vector<double>)
CommandLineArgumentsAddArgumentMacro(VECTOR_STRING,     std::vector<wchar_t*>)
CommandLineArgumentsAddArgumentMacro(VECTOR_STL_STRING, std::vector<std::wstring>)

//----------------------------------------------------------------------------
#define CommandLineArgumentsAddBooleanArgumentMacro(type, ctype) \
  void CommandLineArguments::AddBooleanArgument(const wchar_t* argument, \
    ctype* variable, const wchar_t* help) \
  { \
    this->AddArgument(argument, CommandLineArguments::NO_ARGUMENT, \
      CommandLineArguments::type##_TYPE, variable, help); \
  }

CommandLineArgumentsAddBooleanArgumentMacro(BOOL,       bool)
CommandLineArgumentsAddBooleanArgumentMacro(INT,        int)
CommandLineArgumentsAddBooleanArgumentMacro(DOUBLE,     double)
CommandLineArgumentsAddBooleanArgumentMacro(STRING,     wchar_t*)
CommandLineArgumentsAddBooleanArgumentMacro(STL_STRING, std::wstring)

//----------------------------------------------------------------------------
void CommandLineArguments::SetClientData(void* client_data)
{
  this->Internals->ClientData = client_data;
}

//----------------------------------------------------------------------------
void CommandLineArguments::SetUnknownArgumentCallback(
  CommandLineArguments::ErrorCallbackType callback)
{
  this->Internals->UnknownArgumentCallback = callback;
}

//----------------------------------------------------------------------------
const wchar_t* CommandLineArguments::GetHelp(const wchar_t* arg)
{
  CommandLineArguments::Internal::CallbacksMap::iterator it
    = this->Internals->Callbacks.find(arg);
  if ( it == this->Internals->Callbacks.end() )
    {
    return 0;
    }

  // Since several arguments may point to the same argument, find the one this
  // one point to if this one is pointing to another argument.
  CommandLineArgumentsCallbackStructure *cs = &(it->second);
  for(;;)
    {
    CommandLineArguments::Internal::CallbacksMap::iterator hit
      = this->Internals->Callbacks.find(cs->Help);
    if ( hit == this->Internals->Callbacks.end() )
      {
      break;
      }
    cs = &(hit->second);
    }
  return cs->Help;
}

//----------------------------------------------------------------------------
void CommandLineArguments::SetLineLength(unsigned int ll)
{
  if ( ll < 9 || ll > 1000 )
    {
    return;
    }
  this->LineLength = ll;
  this->GenerateHelp();
}

//----------------------------------------------------------------------------
const wchar_t* CommandLineArguments::GetArgv0()
{
  return this->Internals->Argv0.c_str();
}

//----------------------------------------------------------------------------
unsigned int CommandLineArguments::GetLastArgument()
{
  return static_cast<unsigned int>(this->Internals->LastArgument + 1);
}

//----------------------------------------------------------------------------
void CommandLineArguments::GenerateHelp()
{
  std::wostringstream str;

  // Collapse all arguments into the map of vectors of all arguments that do
  // the same thing.
  CommandLineArguments::Internal::CallbacksMap::iterator it;
  typedef std::map<CommandLineArguments::Internal::String,
     CommandLineArguments::Internal::SetOfStrings > MapArgs;
  MapArgs mp;
  MapArgs::iterator mpit, smpit;
  for ( it = this->Internals->Callbacks.begin();
    it != this->Internals->Callbacks.end();
    it ++ )
    {
    CommandLineArgumentsCallbackStructure *cs = &(it->second);
    mpit = mp.find(cs->Help);
    if ( mpit != mp.end() )
      {
      mpit->second.insert(it->first);
      mp[it->first].insert(it->first);
      }
    else
      {
      mp[it->first].insert(it->first);
      }
    }
  for ( it = this->Internals->Callbacks.begin();
    it != this->Internals->Callbacks.end();
    it ++ )
    {
    CommandLineArgumentsCallbackStructure *cs = &(it->second);
    mpit = mp.find(cs->Help);
    if ( mpit != mp.end() )
      {
      mpit->second.insert(it->first);
      smpit = mp.find(it->first);
      CommandLineArguments::Internal::SetOfStrings::iterator sit;
      for ( sit = smpit->second.begin(); sit != smpit->second.end(); sit++ )
        {
        mpit->second.insert(*sit);
        }
      mp.erase(smpit);
      }
    else
      {
      mp[it->first].insert(it->first);
      }
    }

  // Find the length of the longest string
  CommandLineArguments::Internal::String::size_type maxlen = 0;
  for ( mpit = mp.begin();
    mpit != mp.end();
    mpit ++ )
    {
    CommandLineArguments::Internal::SetOfStrings::iterator sit;
    for ( sit = mpit->second.begin(); sit != mpit->second.end(); sit++ )
      {
      CommandLineArguments::Internal::String::size_type clen = sit->size();
      switch ( this->Internals->Callbacks[*sit].ArgumentType )
        {
        case CommandLineArguments::NO_ARGUMENT:     clen += 0; break;
        case CommandLineArguments::CONCAT_ARGUMENT: clen += 3; break;
        case CommandLineArguments::SPACE_ARGUMENT:  clen += 4; break;
        case CommandLineArguments::EQUAL_ARGUMENT:  clen += 4; break;
        }
      if ( clen > maxlen )
        {
        maxlen = clen;
        }
      }
    }

  // Create format for that string
  wchar_t format[80];
  swprintf_s(format, L"  %%-%us  ", static_cast<unsigned int>(maxlen));

  maxlen += 4; // For the space before and after the option

  // Print help for each option
  for ( mpit = mp.begin();
    mpit != mp.end();
    mpit ++ )
    {
    CommandLineArguments::Internal::SetOfStrings::iterator sit;
    for ( sit = mpit->second.begin(); sit != mpit->second.end(); sit++ )
      {
      str << std::endl;
      wchar_t argument[100];
      swprintf_s(argument, L"%s", sit->c_str());
      switch ( this->Internals->Callbacks[*sit].ArgumentType )
        {
        case CommandLineArguments::NO_ARGUMENT: break;
        case CommandLineArguments::CONCAT_ARGUMENT: wcscat(argument, L"opt"); break;
        case CommandLineArguments::SPACE_ARGUMENT:  wcscat(argument,L" opt"); break;
        case CommandLineArguments::EQUAL_ARGUMENT:  wcscat(argument, L"=opt"); break;
        case CommandLineArguments::MULTI_ARGUMENT:  wcscat(argument,L" opt opt ..."); break;
        }
      wchar_t buffer[80];
      swprintf_s(buffer, format, argument);
      str << buffer;
      }
    const wchar_t* ptr = this->Internals->Callbacks[mpit->first].Help;
    size_t len = wcslen(ptr);
    int cnt = 0;
    while ( len > 0)
      {
      // If argument with help is longer than line length, split it on previous
      // space (or tab) and continue on the next line
      CommandLineArguments::Internal::String::size_type cc;
      for ( cc = 0; ptr[cc]; cc ++ )
        {
        if ( *ptr == ' ' || *ptr == '\t' )
          {
          ptr ++;
          len --;
          }
        }
      if ( cnt > 0 )
        {
        for ( cc = 0; cc < maxlen; cc ++ )
          {
          str << L" ";
          }
        }
      CommandLineArguments::Internal::String::size_type skip = len;
      if ( skip > this->LineLength - maxlen )
        {
        skip = this->LineLength - maxlen;
        for ( cc = skip-1; cc > 0; cc -- )
          {
          if ( ptr[cc] == ' ' || ptr[cc] == '\t' )
            {
            break;
            }
          }
        if ( cc != 0 )
          {
          skip = cc;
          }
        }
      str.write(ptr, static_cast<std::streamsize>(skip));
      str << std::endl;
      ptr += skip;
      len -= skip;
      cnt ++;
      }
    }
  /*
  // This can help debugging help string
  str << endl;
  unsigned int cc;
  for ( cc = 0; cc < this->LineLength; cc ++ )
    {
    str << cc % 10;
    }
  str << endl;
  */
  this->Help = str.str();
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  bool* variable, const std::wstring& value)
{
  if ( value == L"1" || value == L"ON" || value == L"on" || value == L"On" ||
    value == L"TRUE" || value == L"true" || value == L"True" ||
    value == L"yes" || value == L"Yes" || value == L"YES" )
    {
    *variable = true;
    }
  else
    {
    *variable = false;
    }
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  int* variable, const std::wstring& value)
{
  wchar_t* res = 0;
  *variable = static_cast<int>(wcstol(value.c_str(), &res, 10));
  //if ( res && *res )
  //  {
  //  Can handle non-int
  //  }
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  double* variable, const std::wstring& value)
{
  wchar_t* res = 0;
  *variable = wcstod(value.c_str(), &res);
  //if ( res && *res )
  //  {
  //  Can handle non-double
  //  }
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  wchar_t** variable, const std::wstring& value)
{
  if ( *variable )
    {
    delete [] *variable;
    *variable = 0;
    }
  *variable = new wchar_t[ value.size() + 1 ];
  wcscpy_s(*variable,value.size(), value.c_str());
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  std::wstring* variable, const std::wstring& value)
{
  *variable = value;
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  std::vector<bool>* variable, const std::wstring& value)
{
  bool val = false;
  if ( value == L"1" || value == L"ON" || value == L"on" || value == L"On" ||
    value == L"TRUE" || value == L"true" || value == L"True" ||
    value == L"yes" || value == L"Yes" || value == L"YES" )
    {
    val = true;
    }
  variable->push_back(val);
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  std::vector<int>* variable, const std::wstring& value)
{
  wchar_t* res = 0;
  variable->push_back(static_cast<int>(wcstol(value.c_str(), &res, 10)));
  //if ( res && *res )
  //  {
  //  Can handle non-int
  //  }
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  std::vector<double>* variable, const std::wstring& value)
{
  wchar_t* res = 0;
  variable->push_back(wcstod(value.c_str(), &res));
  //if ( res && *res )
  //  {
  //  Can handle non-int
  //  }
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  std::vector<wchar_t*>* variable, const std::wstring& value)
{
  wchar_t* var = new wchar_t[ value.size() + 1 ];
  wcscpy_s(var,value.size(), value.c_str());
  variable->push_back(var);
}

//----------------------------------------------------------------------------
void CommandLineArguments::PopulateVariable(
  std::vector<std::wstring>* variable,
  const std::wstring& value)
{
  variable->push_back(value);
}

//----------------------------------------------------------------------------
bool CommandLineArguments::PopulateVariable(CommandLineArgumentsCallbackStructure* cs,
  const wchar_t* value)
{
  // Call the callback
  if ( cs->Callback )
    {
    if ( !cs->Callback(cs->Argument, value, cs->CallData) )
      {
      this->Internals->LastArgument --;
      return 0;
      }
    }
  if ( cs->Variable )
    {
    std::wstring var = L"1";
    if ( value )
      {
      var = value;
      }
    switch ( cs->VariableType )
      {
    case CommandLineArguments::INT_TYPE:
      this->PopulateVariable(static_cast<int*>(cs->Variable), var);
      break;
    case CommandLineArguments::DOUBLE_TYPE:
      this->PopulateVariable(static_cast<double*>(cs->Variable), var);
      break;
    case CommandLineArguments::STRING_TYPE:
      this->PopulateVariable(static_cast<wchar_t**>(cs->Variable), var);
      break;
    case CommandLineArguments::STL_STRING_TYPE:
      this->PopulateVariable(static_cast<std::wstring*>(cs->Variable), var);
      break;
    case CommandLineArguments::BOOL_TYPE:
      this->PopulateVariable(static_cast<bool*>(cs->Variable), var);
      break;
    case CommandLineArguments::VECTOR_BOOL_TYPE:
      this->PopulateVariable(static_cast<std::vector<bool>*>(cs->Variable), var);
      break;
    case CommandLineArguments::VECTOR_INT_TYPE:
      this->PopulateVariable(static_cast<std::vector<int>*>(cs->Variable), var);
      break;
    case CommandLineArguments::VECTOR_DOUBLE_TYPE:
      this->PopulateVariable(static_cast<std::vector<double>*>(cs->Variable), var);
      break;
    case CommandLineArguments::VECTOR_STRING_TYPE:
      this->PopulateVariable(static_cast<std::vector<wchar_t*>*>(cs->Variable), var);
      break;
    case CommandLineArguments::VECTOR_STL_STRING_TYPE:
      this->PopulateVariable(static_cast<std::vector<std::wstring>*>(cs->Variable), var);
      break;
    default:
      std::wcerr << L"Got unknown variable type: \"" << cs->VariableType << L"\"" << std::endl;
      this->Internals->LastArgument --;
      return 0;
      }
    }
  return 1;
}


} // namespace KWSYS_NAMESPACE
