//////////
#include <string>
#include <string_view>
#include <vector>

inline bool isWhitespace(char C) {
  return C == ' ' || C == '\t' || C == '\r' || C == '\n';
}
inline bool isWhitespaceOrNull(char C) { return isWhitespace(C) || C == '\0'; }

inline bool isQuote(char C) { return C == '\"' || C == '\''; }

///  * Otherwise, backslashes are interpreted literally.
inline size_t parseBackslash(std::wstring_view Src, size_t I,
                             std::wstring &Token) {
  size_t E = Src.size();
  int BackslashCount = 0;
  // Skip the backslashes.
  do {
    ++I;
    ++BackslashCount;
  } while (I != E && Src[I] == '\\');

  bool FollowedByDoubleQuote = (I != E && Src[I] == '"');
  if (FollowedByDoubleQuote) {
    Token.append(BackslashCount / 2, '\\');
    if (BackslashCount % 2 == 0)
      return I - 1;
    Token.push_back('"');
    return I;
  }
  Token.append(BackslashCount, '\\');
  return I - 1;
}

class ArgvTokenize {
public:
  ArgvTokenize() = default;
  ArgvTokenize(const ArgvTokenize &) = delete;
  ArgvTokenize &operator=(const ArgvTokenize &) = delete;
  void Tokenize(std::wstring_view Src) {
    std::wstring Token;

    // This is a small state machine to consume characters until it reaches the
    // end of the source string.
    enum { INIT, UNQUOTED, QUOTED } State = INIT;
    for (size_t I = 0, E = Src.size(); I != E; ++I) {
      char C = Src[I];

      // INIT state indicates that the current input index is at the start of
      // the string or between tokens.
      if (State == INIT) {
        if (isWhitespaceOrNull(C)) {
          continue;
        }
        if (C == '"') {
          State = QUOTED;
          continue;
        }
        if (C == '\\') {
          I = parseBackslash(Src, I, Token);
          State = UNQUOTED;
          continue;
        }
        Token.push_back(C);
        State = UNQUOTED;
        continue;
      }

      // UNQUOTED state means that it's reading a token not quoted by double
      // quotes.
      if (State == UNQUOTED) {
        // Whitespace means the end of the token.
        if (isWhitespaceOrNull(C)) {
          argv_.push_back(std::move(Token));
          State = INIT;
          continue;
        }
        if (C == '"') {
          State = QUOTED;
          continue;
        }
        if (C == '\\') {
          I = parseBackslash(Src, I, Token);
          continue;
        }
        Token.push_back(C);
        continue;
      }

      // QUOTED state means that it's reading a token quoted by double quotes.
      if (State == QUOTED) {
        if (C == '"') {
          if (I < (E - 1) && Src[I + 1] == '"') {
            // Consecutive double-quotes inside a quoted string implies one
            // double-quote.
            Token.push_back('"');
            I = I + 1;
            continue;
          }
          State = UNQUOTED;
          continue;
        }
        if (C == '\\') {
          I = parseBackslash(Src, I, Token);
          continue;
        }
        Token.push_back(C);
      }
    }
    // Append the last token after hitting EOF with no whitespace.
    if (!Token.empty()) {
      argv_.push_back(std::move(Token));
    }
  }

private:
  std::vector<std::wstring> argv_;
};
