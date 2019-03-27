//	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
//	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
//
// @file nl.nlsw.Items.cs
//

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

///
/// Base classes for lists of items with attributes properties.
///
/// @author Ernst van der Pols
/// @date 2019-03-27
/// @requires .NET Framework 4.5
///
namespace nl.nlsw.Items {

	///
	/// A CompoundValue is a data value container that can represent a single "line"
	/// of a Comma-Separated-Values data file, as specified in RFC 4180.
	///
	/// The class extends this specification to support nested CompoundValues as well,
	/// i.e. any value can be a comma-separated-value that (recursively) holds another 
	/// list of comma-separated-values, surrounded by parentheses.
	/// This extension provides for a simple format for serializing an ordered, directed 
	/// rooted tree of data nodes.
	///
	/// The class is based on a generic object list. For serialization to string the ToString()
	/// operation of the objects are used. De-serialization builds a CompoundValue tree of strings.
	/// A nested CompoundValue has a link to is Parent CompoundValue.
	/// 
	/// @see https://tools.ietf.org/html/rfc4180
	/// @see https://en.wikipedia.org/wiki/Comma-separated_values
	/// @see https://www.loc.gov/preservation/digital/formats/fdd/fdd000323.shtml
	/// @see https://en.wikipedia.org/wiki/Tree_(graph_theory)
	///
	public class CompoundValue : global::System.Collections.Generic.List<object> {
		const char ValueSeparator = ',';
		const char DoubleQuote = '"';
		const char CompoundOpen = '(';
		const char CompoundClose = ')';

		/// Characters that require escaping
		public static readonly char[] Delimiters = {',','"','\r','\n',
			CompoundOpen,CompoundClose};
		
		/// The depth of this node in the tree.
		public int Depth {
			get {
				int result = 0;
				for (CompoundValue p = Parent; p != null; result++, p = p.Parent) {
				}
				return result;
			}
		}
	
		/// The parent node.
		public CompoundValue Parent { get; set; }

		/// Default Constructor (defines the parent)
		public CompoundValue(CompoundValue parent = null) {
			Parent = parent;
		}

		/// Initializing constructor
		public CompoundValue(string value) {
			FromString(value);
		}
		
		/// Get a value at the specified index, null if not present or index out-of-range.
		public object GetValue(int index) {
			if (index < Count) {
				return this[index];
			}
			return null;
		}
		
		/// Set the CompoundValue to the values in the list, array, or other enumerable
		/// @note List<T> has a constructor for IEnumerable, but no assignment
		public void FromEnumerable(IEnumerable list) {
			Clear();
			if (list != null) {
				foreach (object item in list) {
					Add(item);
				}
			}
		}

		/// Set the CompoundValue to the (comma-separated) values specified in the string.
		/// @exception FormatException if the value has an invalid format
		public void FromString(string value) {
			Clear();
			if (string.IsNullOrEmpty(value)) {
				return;
			}
			CompoundValue current = this;
			int start = 0, position;
			for (; (position = value.IndexOfAny(Delimiters,start)) != -1; start = position + 1) {
				switch (value[position]) {
				case ValueSeparator:
					current.Add(value.Substring(start,position - start));
					break;
				case DoubleQuote:
					if (position != start) {
						// this delimiter must here be at start of field
						throw new FormatException("unescaped DOUBLE-QUOTE character in CompoundValue");
					}
					start++;
					{
						// escaped value, scan for next DoubleQuote
						position = value.IndexOf(DoubleQuote,start);
						bool doubles = false;
						while ((position >= 0) && ((position + 1) < value.Length) && (value[position + 1] == DoubleQuote)) {
							// escaped DoubleQuote: needs to be replaced with single DoubleQuote
							doubles = true;
							position = value.IndexOf(DoubleQuote,position + 2);
						}
						if (position < 0) {
							throw new FormatException("unclosed escaped CompoundValue (missing DOUBLE-QUOTE)");
						}
						string s = value.Substring(start);
						if (doubles) {
							s = s.Replace("\"\"","\"");
						}
						current.Add(s);
					}
					break;
				case CompoundOpen:
					if (position != start) {
						// this delimiter must here be at start of field
						throw new FormatException(String.Format("unescaped '{0}' character in CompoundValue",CompoundOpen));
					}
					// increase nesting level
					CompoundValue cv = new CompoundValue(current);
					// set at this location
					current.Add(cv);
					// switch reading to nested level
					current = cv;
					break;
				case CompoundClose:
					current.Add(value.Substring(start,position - start));
					// decrease nesting level
					if (current.Parent == null) {
						throw new FormatException("unbalanced CompoundValue: closing delimiter without earlier opening delimiter");
					}
					current = current.Parent;
					// skip the CompoundClose
					position++;
					// this delimiter must be followed by 1) nothing (end-of-line) or 2) comma
					if ((position < value.Length) && (value[position] != ValueSeparator)) {
						throw new FormatException(String.Format("missing value separator '{0}' after enquoted value",ValueSeparator));
					}
					break;
				case '\r':
					throw new FormatException(String.Format("unescaped CARRIAGE RETURN character in CompoundValue",CompoundOpen));
				case '\n':
					throw new FormatException(String.Format("unescaped LINEFEED character in CompoundValue",CompoundOpen));
				default:
					throw new FormatException("unescaped CompoundValue delimiter encountered: "+value[position]);
				}
			}
			if (start < value.Length) {
				// no delimiters found, a single simple string has remained
				current.Add(value.Substring(start));
			}
			if (current != this) {
				throw new FormatException("unbalanced CompoundValue: opening delimiter without closing delimiter");
			}
		}

		/// Set the value at the specified index.
		/// If the index is outside the current list, the list is expanded to
		public void SetValue(int index, object value) {
			while (index >= Count) {
				Add(null);
			}
			this[index] = value;
		}
		
		///
		/// Match the (text) value or the fields of the CompoundValue with the specified regular expression.
		/// @return the first successful match encountered, or null otherwise
		public static Match TextValueMatch(object value, System.Text.RegularExpressions.Regex regex) {
			Match result = null;
			if (value is CompoundValue) {
				for (int i = 0; i < ((CompoundValue)value).Count; i++) {
					result = TextValueMatch(((CompoundValue)value)[i],regex);
					if ((result != null) && result.Success) {
						return result;
					}
				}
			}
			else if (value != null) {
				result = regex.Match(value.ToString());
				if (result != null && result.Success) {
					return result;
				}
			}
			// null encountered or no success
			return null;
		}

		///
		/// Test whether the (compound) text value matches the regular expression.
		/// 
		public static bool TextValueMatches(object value, System.Text.RegularExpressions.Regex regex) {
			Match m = TextValueMatch(value,regex);
			return (m != null) && m.Success;
		}

		/// Get the fields as a string, separated with the specified separator.
		/// Optionally, empty fields are included in the result, and nested fields can be indicated.
		public string ToFormattedString(int[] indices = null, string separator = " ", string open = null, string close = null, bool includeEmpty = false) {
			StringBuilder sb = new StringBuilder();
			ToStringBuilderFormatted(sb,indices,separator,open,close,includeEmpty);
			return sb.ToString();
		}
		
		public override string ToString() {
			StringBuilder sb = new StringBuilder();
			ToStringBuilder(sb);
			return sb.ToString();
		}

		/// Appends the CompoundValue to the string builder.
		/// Uses recursion to write nested CompoundValues.
		public void ToStringBuilder(StringBuilder sb) {
			if (Parent != null) {
				sb.Append(CompoundOpen);
			}
			for (int i = 0; i < Count; i++) {
				object v = this[i];
				if (i > 0) {
					sb.Append(ValueSeparator);
				}
				if (v is CompoundValue) {
					((CompoundValue)v).ToStringBuilder(sb);
				}
				else if (v != null) {
					string s = v.ToString();
					if (s.IndexOfAny(Delimiters) >= 0) {
						// enclose this value with DoubleQuotes
						sb.Append(DoubleQuote);
						int start = sb.Length;
						sb.Append(s);
						// replace DoubleQuote with 2DoubleQuote
						sb.Replace("\"","\"\"",start,s.Length);
						sb.Append(DoubleQuote);
					}
					else {
						sb.Append(s);
					}
				}
			}
			
			if (Parent != null) {
				sb.Append(CompoundClose);
			}
		}

		/// Appends the CompoundValue to the string builder, using the specified fields and format delimiters.
		/// Uses recursion to write nested CompoundValues.
		/// @param sb the output string builder
		/// @param indices the field indices to include; these apply only to this level of values; null means all fields.
		/// @param separator the separator to use
		/// @param open the nested value(s) opening delimiter
		/// @param close the nested value(s) closing delimiter (ignored if 'open' is null)
		/// @param includeEmpty By default empty fields are not included, but if you want the delimiters can be written for empty fields as well.
		public void ToStringBuilderFormatted(StringBuilder sb, int[] indices = null, string separator = " ", string open = null, string close = null, bool includeEmpty = false) {
			int openPos = sb.Length;
			if (Parent != null) {
				sb.Append(open);
			}
			int startPos = sb.Length;
			for (int i = 0; (indices == null) ? i < Count : i < indices.Length; i++) {
				object v = this[(indices == null) ? i : indices[i]];
				int separatorPos = -1;
				if (sb.Length > startPos) {
					separatorPos = sb.Length;
					sb.Append(separator);
				}
				if (v is CompoundValue) {
					((CompoundValue)v).ToStringBuilderFormatted(sb,null,separator,open,close,includeEmpty);
				}
				else if (v != null) {
					string s = v.ToString();
					sb.Append(s);
				}
				if (!includeEmpty && (separatorPos >= 0) && (separator != null)) {
					// determine if we should remove the separator
					if (sb.Length == (separatorPos + separator.Length)) {
						sb.Remove(separatorPos,separator.Length);
					}
				}
			}
			if (Parent != null && (open != null)) {
				if (!includeEmpty) {
					// determine if we should remove the opening delimiter
					if (sb.Length == (openPos + open.Length)) {
						sb.Remove(openPos,open.Length);
					}
				}
				else {
					sb.Append(close);
				}
			}
		}
	}
}
