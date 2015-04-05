

#ifndef COMMANDLINEARGUMENTSEX_HPP
#define COMMANDLINEARGUMENTSEX_HPP

#include <string>
#include <vector>

namespace Force{
class CommandLineArgumentsInternal;
struct CommandLineArgumentsCallbackStructure;


class CommandLineArguments {
public:
  CommandLineArguments();
  ~CommandLineArguments();


  enum ArgumentTypeEnum {
    NO_ARGUMENT,
    CONCAT_ARGUMENT,
    SPACE_ARGUMENT,
    EQUAL_ARGUMENT,
    MULTI_ARGUMENT
  };


  enum VariableTypeEnum {
    NO_VARIABLE_TYPE = 0,   // The variable is not specified
    INT_TYPE,               // The variable is integer (int)
    BOOL_TYPE,              // The variable is boolean (bool)
    DOUBLE_TYPE,            // The variable is float (double)
    STRING_TYPE,            // The variable is string (char*)
    STL_STRING_TYPE,        // The variable is string (char*)
    VECTOR_INT_TYPE,        // The variable is integer (int)
    VECTOR_BOOL_TYPE,       // The variable is boolean (bool)
    VECTOR_DOUBLE_TYPE,     // The variable is float (double)
    VECTOR_STRING_TYPE,     // The variable is string (char*)
    VECTOR_STL_STRING_TYPE, // The variable is string (char*)
    LAST_VARIABLE_TYPE
  };

  /**
   * Prototypes for callbacks for callback interface.
   */
  typedef int (*CallbackType)(const wchar_t *argument, const wchar_t *value,
                              void *call_data);
  typedef int (*ErrorCallbackType)(const wchar_t *argument, void *client_data);

  /**
   * Initialize internal data structures. This should be called before parsing.
   */
  void Initialize(int argc, const wchar_t *const argv[]);
  void Initialize(int argc, wchar_t *argv[]);

  /**
   * Initialize internal data structure and pass arguments one by one. This is
   * convenience method for use from scripting languages where argc and argv
   * are not available.
   */
  void Initialize();
  void ProcessArgument(const wchar_t *arg);

  /**
   * This method will parse arguments and call appropriate methods.
   */
  int Parse();

  /**
   * This method will add a callback for a specific argument. The arguments to
   * it are argument, argument type, callback method, and call data. The
   * argument help specifies the help string used with this option. The
   * callback and call_data can be skipped.
   */
  void AddCallback(const wchar_t *argument, ArgumentTypeEnum type,
                   CallbackType callback, void *call_data, const wchar_t *help);

  /**
   * Add handler for argument which is going to set the variable to the
   * specified value. If the argument is specified, the option is casted to the
   * appropriate type.
   */
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type, bool *variable,
                   const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type, int *variable,
                   const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   double *variable, const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type, wchar_t **variable,
                   const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   std::wstring *variable, const wchar_t *help);

  /**
   * Add handler for argument which is going to set the variable to the
   * specified value. If the argument is specified, the option is casted to the
   * appropriate type. This will handle the multi argument values.
   */
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   std::vector<bool> *variable, const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   std::vector<int> *variable, const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   std::vector<double> *variable, const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   std::vector<wchar_t *> *variable, const wchar_t *help);
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   std::vector<std::wstring> *variable, const wchar_t *help);

  /**
   * Add handler for boolean argument. The argument does not take any option
   * and if it is specified, the value of the variable is true/1, otherwise it
   * is false/0.
   */
  void AddBooleanArgument(const wchar_t *argument, bool *variable,
                          const wchar_t *help);
  void AddBooleanArgument(const wchar_t *argument, int *variable,
                          const wchar_t *help);
  void AddBooleanArgument(const wchar_t *argument, double *variable,
                          const wchar_t *help);
  void AddBooleanArgument(const wchar_t *argument, wchar_t **variable,
                          const wchar_t *help);
  void AddBooleanArgument(const wchar_t *argument, std::wstring *variable,
                          const wchar_t *help);

  /**
   * Set the callbacks for error handling.
   */
  void SetClientData(void *client_data);
  void SetUnknownArgumentCallback(ErrorCallbackType callback);

  /**
   * Get remaining arguments. It allocates space for argv, so you have to call
   * delete[] on it.
   */
  void GetRemainingArguments(int *argc, wchar_t ***argv);
  void DeleteRemainingArguments(int argc, wchar_t ***argv);

  /**
   * If StoreUnusedArguments is set to true, then all unknown arguments will be
   * stored and the user can access the modified argc, argv without known
   * arguments.
   */
  void StoreUnusedArguments(bool val) { this->StoreUnusedArgumentsFlag = val; }
  void GetUnusedArguments(int *argc, wchar_t ***argv);

  /**
   * Return string containing help. If the argument is specified, only return
   * help for that argument.
   */
  const wchar_t *GetHelp() { return this->Help.c_str(); }
  const wchar_t *GetHelp(const wchar_t *arg);

  /**
   * Get / Set the help line length. This length is used when generating the
   * help page. Default length is 80.
   */
  void SetLineLength(unsigned int);
  unsigned int GetLineLength();

  /**
   * Get the executable name (argv0). This is only available when using
   * Initialize with argc/argv.
   */
  const wchar_t *GetArgv0();

  /**
   * Get index of the last argument parsed. This is the last argument that was
   * parsed ok in the original argc/argv list.
   */
  unsigned int GetLastArgument();

protected:
  void GenerateHelp();

  //! This is internal method that registers variable with argument
  void AddArgument(const wchar_t *argument, ArgumentTypeEnum type,
                   VariableTypeEnum vtype, void *variable, const wchar_t *help);

  bool GetMatchedArguments(std::vector<std::wstring> *matches,
                           const std::wstring &arg);

  //! Populate individual variables
  bool PopulateVariable(CommandLineArgumentsCallbackStructure *cs,
                        const wchar_t *value);

  //! Populate individual variables of type ...
  void PopulateVariable(bool *variable, const std::wstring &value);
  void PopulateVariable(int *variable, const std::wstring &value);
  void PopulateVariable(double *variable, const std::wstring &value);
  void PopulateVariable(wchar_t **variable, const std::wstring &value);
  void PopulateVariable(std::wstring *variable, const std::wstring &value);
  void PopulateVariable(std::vector<bool> *variable, const std::wstring &value);
  void PopulateVariable(std::vector<int> *variable, const std::wstring &value);
  void PopulateVariable(std::vector<double> *variable,
                        const std::wstring &value);
  void PopulateVariable(std::vector<wchar_t *> *variable,
                        const std::wstring &value);
  void PopulateVariable(std::vector<std::wstring> *variable,
                        const std::wstring &value);

  typedef CommandLineArgumentsInternal Internal;
  Internal *Internals;
  std::wstring Help;

  unsigned int LineLength;

  bool StoreUnusedArgumentsFlag;
};
}

#endif
