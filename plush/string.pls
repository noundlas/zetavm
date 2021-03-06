var math = import "std/math/0";

/**
 * Returns a string representation of the passed value. Calls obj:toString() on
 * objects.
 */
exports.toString = function(e)
{
    var type = typeof e;
    if (type == "object")
    {
        return e:toString();
    }
    if (type == "string")
    {
        return e;
    }
    if (type == "int32")
    {
        return exports.intToString(e, 10);
    }
    if (e == true)
    {
        return "true";
    }
    if (e == false)
    {
        return "false";
    }
    assert(false, "toString: cannot convert value of type " + type + " to string");
};

/**
 * Converts a integer to a string representation in a given base.
 *
 * example: intToString(n, 10) produces n in base 10
 */
exports.intToString = function(int, base)
{
    //We run out of letters in this case
    assert(0 <= base && base <= 26);

    //handle 0 explicitely, since it would be an empty string otherwise
    if (int == 0)
    {
        return "0";
    }
    var res = "";
    var isNegative = false;
    if (int < 0)
    {
        int = -int;
        isNegative = true;
    }

    for (;int != 0;)
    {
        var rem = int % base;
        int = math.idiv(int, base);
        //Assumes ascii-like character codes
        if (rem > 9)
        {
            rem -= 10;
            rem += exports.toCharCode('a');
        }
        else
        {
            rem += exports.toCharCode('0');
        }
        res += exports.fromCharCode(rem);
    }
    if (isNegative)
    {
        res += "-";
    }
    return reverseByteString(res);
};

/**
 * Parses a string into an integer. Throws an exception if string is not a valid
 * integer number of the given radix.
 *
 * example: parseInt("123", 10) == 123;
 * example: parseInt("a", 16) == 10;
 */
exports.parseInt = function(string, radix)
{
    string = exports.toLower(string);
    assert(radix > 1 && radix < 26);
    if (string == "")
    {
        throw "argument is empty string";
    }
    var negative = false;
    var pos = 0;
    if (string == "-")
    {
        throw string + " is not a number";
    }
    if (string[0] == "-")
    {
        negative = true;
        pos += 1;
    }
    var num = 0;
    //Assumes ascii like charcodes
    var zeroCharCode = exports.toCharCode("0");
    var nineCharCode = exports.toCharCode("9");
    var aCharCode = exports.toCharCode("a");
    var zCharCode = exports.toCharCode("z");
    for(; pos != string.length; pos += 1)
    {
        var char = exports.toCharCode(string[pos]);
        if (char < zeroCharCode || (char > nineCharCode && char < aCharCode) || char > zCharCode)
        {
            throw "character" + exports.fromCharCode(char) + " is not a number";
        }

        if (char >= aCharCode)
        {
            char -= aCharCode;
            char += 10;
        }
        else
        {
            char -= zeroCharCode;
        }
        if (char < 0 || char >= radix)
        {
            throw "character " + string[pos] + " is not a numeral in base " + exports.toString(radix);
        }

        num *= radix;
        num += char;
    }

    if (negative)
    {
        return -num; 
    }
    else
    {
        return num;
    }
};

/**
 * Provides very simple string formating. toString is called to convert values into strings.
 *
 * example: format("{}, {}", [1, 2]) == "1, 2";
 * example: format("{1}, {0}", [1, 2]) == "2, 1";
 * example: format("{x}, {y}", {x:1, y:2}) == "1, 2";
 */
exports.format = function(fmt, args)
{
    var accum = "";
    var argcounter = 0;
    var openingPos = 0;
    var pos = 0;
    for (;true;)
    {
        openingPos = indexOfChar(fmt, "{", pos);
        if (openingPos == -1)
        {
            //No more opening braces found
            accum += exports.substring(fmt, pos, fmt.length);
            return accum;
        }
        accum += exports.substring(fmt, pos, openingPos);
        var closingPos = indexOfChar(fmt, "}", openingPos);
        if (closingPos == -1)
        {
            assert(false, "Opening braces without closing in format string " + fmt);
        }
        var str = exports.substring(fmt, openingPos + 1, closingPos);
        if (str == "")
        {
            accum += exports.toString(args[argcounter]);
            argcounter += 1;
        }
        else
        {
            var property = 0;
            try {
                property = exports.parseInt(str, 10);
            } catch (e) {
                //Number parsing failed, so its probably not an int, try to
                //acces the object property
                property = str;
            }
            accum += exports.toString(args[property]);
        }
        pos = closingPos + 1;
    }
};

/**
 * Returns the byte value of a given character as an integer.
 *
 * example: toCharCode("a") == 97
 */
exports.toCharCode = function(char)
{
    return $get_char_code(char, 0);
};

/**
 * Returns the character that corresponds to a byte value.
 *
 * example: fromCharCode(97) = "a"
 */
exports.fromCharCode = function(c)
{
    return $char_to_str(c);
};

/**
 * Returns the first index at which a short string or character "needle"
 * appears in a longer string.
 *
 * example: indexOf("banana", "na") == 2
 */
exports.indexOf = function(string, needle)
{
    if (needle.length == 0)
    {
        return 0;
    }
    return indexOfInternal(string, needle, 0);
};

/**
 * Returns a substring of a string starting at start (inclusive) and ending at
 * end (exclusive).
 *
 * example: substring(str, 0, str.length) == str
 * example: substring("banana", 2, 4) == "na"
 */
exports.substring = function(string, start, end)
{
    var result = ""; 
    for (var i = start; i < end; i += 1)
    {
        result += string[i];
    }
    return result;
};

exports.slice = exports.substring;

/**
 * Splits a string into an array of strings at a specific delimiter.
 * Two consecutive delimiters don't produce an empty string in the result.
 *
 * example: split("a b", " ") == ["a", "b"]
 */
exports.split = function(string, delimiter)
{
    var result = [];     
    for(var currentpos = 0; currentpos < string.length;)
    {
        //TODO(mfunk): reuse boyer moore tables, don't recalculate them
        var nextpos = indexOfInternal (string, delimiter, currentpos);
        if (nextpos == -1)
        {
            nextpos = string.length;
        }
        //Don't include empty strings
        if (currentpos != nextpos)
        {
            result:push(exports.substring(string, currentpos, nextpos));
        }
        currentpos = nextpos + delimiter.length;
    }
    return result;
};

/**
 * Joins an array of string into a single string by interleaving them with a
 * delimiter.
 *
 * example: join(["a", "b"], " ") )) == "a b"
 */
exports.join = function(arrayofstrings, delimiter)
{
    var result = "";
    for (var i = 0; i < arrayofstrings.length - 1; i += 1)
    {
        result += arrayofstrings[i];
        result += delimiter;
    }
    result += arrayofstrings[arrayofstrings.length -1]; 
    return result;
};

/**
 * Replaces all occurences of needle with the replacement string in string and
 * returns the resulting string.
 *
 * example: replace("Banana", "na", "dog") == "Badogdog"
 */
exports.replace = function(string, needle, replacement)
{
    // We can't use split + join
    var result = "";
    for (var currentpos = 0; currentpos < string.length;)
    {
        //TODO(mfunk): reuse boyer moore tables, don't recalculate them
        var nextpos = indexOfInternal (string, needle, currentpos);
        if (nextpos == -1)
        {
            nextpos = string.length;
        }
        result += exports.substring(string, currentpos, nextpos);
        if (!(nextpos == string.length))
        {
            result += replacement;
        }
        currentpos = nextpos + needle.length;
    }
    return result;
};

/**
 * Returns true iff a character is one of the three whitespace characters ' ',
 * '\t' or '\n'
 */
exports.isSpace = function (ch)
{
    return ch == ' ' || ch == '\t' || ch == '\n';
};

/**
 * Returns a string with all leading whitespace removed.
 */
exports.ltrim = function(string)
{
    var i = 0;
    for (; i < string.length; i += 1)
    {
        if (!exports.isSpace(string[i]))
        {
            break;
        }
    }
    return exports.substring(string, i, string.length);
};

/**
 * Returns a string with all trailing whitespace removed.
 */
exports.rtrim = function(string)
{
    var i = string.length - 1;
    for (; i >= 0; i -= 1)
    {
        if (!exports.isSpace(string[i]))
        {
            break;
        }
    }
    return exports.substring(string, 0, i + 1);
};

/**
 * Returns a string with all trailing and leading whitespace removed.
 */
exports.trim = function(string)
{
    return exports.ltrim(exports.rtrim(string));
};

/**
 * Returns a string with all ascii characters converted to lower case.
 */
exports.toLower = function(string)
{
    //Assumes ascii
    var result = "";
    for (var i = 0; i < string.length; i += 1)
    {
        var c = exports.toCharCode(string[i]);
        if (c >= exports.toCharCode("A") && c <= exports.toCharCode("Z"))
        {
            result += exports.fromCharCode(c + 32);
        }
        else
        {
            result += string[i];
        }
    }
    return result;
};

/**
 * Returns a string with all ascii characters converted to upper case.
 */
exports.toUpper = function(string)
{
    //Assumes ascii
    var result = "";
    for (var i = 0; i < string.length; i += 1)
    {
        var c = exports.toCharCode(string[i]);
        if (c >= exports.toCharCode("a") && c <= exports.toCharCode("z"))
        {
            result += exports.fromCharCode(c - 32);
        }
        else
        {
            result += string[i];
        }
    }
    return result;
};

/**
 * Returns true iff a string starts with another string "needle".
 */
exports.startsWith = function(string, needle)
{
    if (string.length < needle.length) 
    {
        return false;
    }
    return exports.substring(string, 0, needle.length) == needle;
};

/**
 * Internal functions below
 */

var reverseByteString = function(string)
{
    var res = ""; 
    for (var i = string.length - 1; i >= 0; i -= 1)
    {
        res += string[i];
    }
    return res;
};

var indexOfChar = function(string, char, start)
{
    //TODO(mfunk): check if sentinel value version is faster
    for (var i = start; i < string.length; i += 1)
    {
        if (string[i] == char)
        {
            return i;
        }
    }

    return -1;
};

/**
 * Implements a boyer moore string search, inspired by the available C and Java
 * implementations on wikipedia
 * https://en.wikipedia.org/wiki/Boyer-Moore_string_search_algorithm
 */
var indexOfString = function(string, needle, start)
{
    var charTable = bmMakeChartable(needle);
    var offsetTable = bmMakeOffsettable(needle);
    for (var i = needle.length - 1 + start; i < string.length;)
    {
        var j = needle.length - 1;
        for (; needle[j] == string[i];)
        {
            if (j == 0)
            {
                return i;
            }
            i -= 1;
            j -= 1;
        }
        // i += needle.length - j; // For naive method
        i += math.max(offsetTable[needle.length - 1 - j], charTable[exports.toCharCode(string[i])]);
    }
    return -1;
};

/**
 * Is needle[p:end] a prefix of needle?
 */
var bmIsPrefix = function(needle, p)
{
    var i = p;
    var j = 0;
    for (;i < needle.length;)
    {
        if (needle[i] != needle[j])
        {
            return false;
        }
        j += 1;
        i += 1;
    }

    return true;
};

/**
 * Creates a table that contains the distances of character c from the end of
 * the needle string.
 */
var bmMakeChartable = function(needle)
{
    var alphabetsize = 256; // we just look at bytes here
    var table = [];
    for (var i = 0; i < alphabetsize; i += 1)
    {
        table:push(needle.length);
    }
    for (var i = 0; i < needle.length - 1; i += 1)
    {
        table[exports.toCharCode(needle[i])] = needle.length - 1 - i;
    }
    return table;
};

/**
 * Returns the maximum length of the substring that ends at p and is a suffix of needle.
 */
var bmSuffixLength = function(needle, p)
{
    var len = 0;
    var i = p;
    var j = needle.length - 1;
    for (; i >= 0 && needle[i] == needle[j];)
    {
        len += 1; 
        i -= 1;
        j -= 1;
    }
    return len;
};

/**
 * Given a mismatch at needle[i], we want to shift by the minimum necessary
 * amount to make a full match possible again
 *
 * case 1:
 * if the suffix starting at i does not occur elsewhere in needle, the next
 * possible match starts after i. if there is a prefix of needle in the suffix
 * starting at i, the next plausible match begins there. Otherwise the match
 * starts past the last character of the suffix
 *
 * case 2:
 * the suffix starting at i does accur elsewhere in needle. Thus we may shift
 * from the other occurence to this one.
 */
var bmMakeOffsettable = function(needle)
{
    //Returns a combination of the H/L tables
    var table = [];
    var lastPrefixPosition = needle.length;
    // first case
    for (var i = needle.length; i > 0; i -= 1)
    {
        if (bmIsPrefix(needle, i))
        {
            lastPrefixPosition = i;
        }
        table:push(lastPrefixPosition - i + needle.length);
    }
    // second case
    for (var i = 0; i < needle.length - 1 ; i += 1)
    {
        var slen = bmSuffixLength(needle, i);
        table[slen] = needle.length - 1 - i + slen;
    }
    return table;
};

var indexOfInternal = function(string, needle, start)
{
    if (needle.length == 1)
    {
        return indexOfChar(string, needle, start);
    }
    else
    {
        return indexOfString(string, needle, start);
    }
};
