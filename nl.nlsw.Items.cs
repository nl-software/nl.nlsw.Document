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
using System.Xml;

///
/// Base classes for collections of items with attributes properties.
///
/// @author Ernst van der Pols
/// @date 2020-09-08
/// @requires .NET Framework 4.5
///
namespace nl.nlsw.Items {

	/// Attributes (or parameters), i.e. key=value pairs
	/// The base class allows for multiple entries with the same key,
	/// using case insensitive CultureInvariant key comparison.
	public class Attributes : System.Collections.Specialized.NameValueCollection {
		
		/// Check if the attribute with the specified name contains the specified value.
		/// Uses a case-sensitive comparison.
		public bool HasValue(string name, string value) {
			string[] values = GetValues(name);
			if (values != null) {
				foreach (string v in values) {
					if (String.Compare(v,value,StringComparison.Ordinal) == 0) {
						return true;
					}
				}
			}
			return false;
		}

		/// Check if the attribute with the specified name contains exactly the specified values.
		/// Uses a comparison as specified.
		public bool HasEqualValues(string name, string[] values, StringComparison comparison = StringComparison.Ordinal) {
			string[] vs = GetValues(name);
			if ((vs == null) ^ (values == null)) {
				return false;
			}
			if (vs != null) {
				if (vs.Length != values.Length) {
					return false;
				}
				foreach (string v1 in vs) {
					bool found = false;
					foreach (string v2 in values) {
						if (String.Compare(v1,v2,comparison) == 0) {
							found = true;
							break;
						}
					}
					if (!found) {
						return false;
					}
				}
			}
			// both null or all strings match
			return true;
		}

		/// Check if the attribute with the specified name has exactly the same
		/// values in the other Attributes.
		/// Uses a case-sensitive comparison.
		public bool HasEqualValues(string name, Attributes other) {
			return HasEqualValues(name,other.GetValues(name),StringComparison.Ordinal);
		}

		/// Check if the attribute with the specified name has exactly the same
		/// values in the other Attributes.
		/// Uses a case-insensitive comparison.
		public bool HasEqualValuesIgnoreCase(string name, Attributes other) {
			return HasEqualValues(name,other.GetValues(name),StringComparison.OrdinalIgnoreCase);
		}

		/// Check if the attribute with the specified name contains the specified value.
		/// Uses a case-insensitive comparison.
		public bool HasValueIgnoreCase(string name, string value) {
			string[] values = GetValues(name);
			if (values != null) {
				foreach (string v in values) {
					if (String.Compare(v,value,StringComparison.OrdinalIgnoreCase) == 0) {
						return true;
					}
				}
			}
			return false;
		}

		/// Add the value once to the attribute with the specified name.
		/// If the attribute already contains this value, it is not added again.
		/// Uses a case-sensitive comparison.
		public void AddOnce(string name, string value) {
			if (HasValue(name,value)) {
				return;
			}
			Add(name,value);
		}

		/// Add the value once to the attribute with the specified name.
		/// If the attribute already contains this value, it is not added again.
		/// Uses a case-insensitive comparison.
		public void AddOnceIgnoreCase(string name, string value) {
			if (HasValueIgnoreCase(name,value)) {
				return;
			}
			Add(name,value);
		}

		/// Remove the specified value from the specified attribute.
		/// Uses a case-insensitive value comparison.
		public void RemoveValue(string name, string value) {
			string[] values = GetValues(name);
			if ((values != null) && (value != null)) {
				Remove(name);
				for (int i = 0; i < values.Length; i++) {
					if (String.Compare(values[i],value,StringComparison.Ordinal) != 0) {
						Add(name,values[i]);
					}
				}
			}
		}

		/// Remove the specified value from the specified attribute.
		/// Uses a case-insensitive value comparison.
		public void RemoveValueIgnoreCase(string name, string value) {
			string[] values = GetValues(name);
			if ((values != null) && (value != null)) {
				Remove(name);
				for (int i = 0; i < values.Length; i++) {
					if (String.Compare(values[i],value,StringComparison.OrdinalIgnoreCase) != 0) {
						Add(name,values[i]);
					}
				}
			}
		}
		
		/// Counterpart of GetValues(), missing in the base class.
		public void SetValues(string name, string[] values) {
			if (values == null || values.Length == 0) {
				Remove(name);
			}
			else {
				Set(name,values[0]);
				for (int i = 1; i < values.Length; i++) {
					Add(name,values[i]);
				}
			}
		}
	}

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

	/// Class of properties that can have multiple values.
	///
	/// The values are typically contained in a CompoundValue container.
	/// Three subclasses can be distinghuished:
	/// - list properties: a list of multiple similar values
	/// - structured properties: a set of sub-properties, each with its own name
	/// - a combination of both, e.g. an ordered list of values
	///
	public class CompoundProperty : Property {

		/// Get the value as CompoundValue
		/// @note may return null
		public CompoundValue CompoundValue {
			get { return Value as CompoundValue; }
			set { Value = value; }
		}
		
		/// Get the names of the compound fields (if any)
		public virtual string[] FieldNames { get; set; }

		/// Get the number of values (first order)
		public int ValueCount {
			get {
				if (Value == null) return 0;
				if (CompoundValue == null) return 1;
				return CompoundValue.Count;
			}
		}

		/// Default constructor
		public CompoundProperty() {
		}

		/// Initializing Constructor
		public CompoundProperty(string name, object value = null) : base(name,value) {
		}

		/// Add the value, optionally at the specified index.
		public void AddValue(object value, int? index = null) {
			// check if we have a compound value to hold the new value
			CompoundValue cv = base.Value as CompoundValue;
			if (cv == null) {
				cv = new CompoundValue();
				if (base.Value != null) {
					// preserve the degenerate first value
					cv.Add(base.Value);
				}
				base.Value = cv;
			}
			if (index == null) {
				// simply add the value to the Value list
				cv.Add(value);
			}
			else {
				// add the new value to the list at the specified index
				object atIndex = cv.GetValue((int)index);
				// do we have a CompoundValue there?
				CompoundValue svc = atIndex as CompoundValue;
				if (svc == null) {
					// no, create one
					svc = new CompoundValue(cv);
					if (atIndex != null) {
						// preserve the (degenerate) first value of the list
						svc.Add(atIndex);
					}
					// set the CompoundValue at the index
					cv.SetValue((int)index,svc);
				}
				// add the value to the list
				svc.Add(value);
			}
		}

		/// Get the name of the compound field at the specified index.
		public string GetFieldName(int index) {
			if (FieldNames == null) {
				throw new Exception("FieldNames not initialized");
			}
			return FieldNames[(index < FieldNames.Length ? index : FieldNames.Length - 1)];
			
		}

		/// Get the value, optionally at the specified indices.
		public object GetValue(int? index = null, int? subIndex = null) {
			object value = base.Value;
			if (index == null) {
				return value;
			}
			if (value is CompoundValue) {
				value = ((CompoundValue)value).GetValue((int)index);
				if (subIndex == null) {
					return value;
				}
				if (value is CompoundValue) {
					return ((CompoundValue)value).GetValue((int)subIndex);
				}
				else if (subIndex == 0) {
					return value;
				}
				return null;
			}
			else if ((index == 0) && (subIndex == null || subIndex == 0)) {
				return value;
			}
			return null;
		}
		
		/// Get the values as string, optionally at the specified field index.
		public string[] GetValuesAsString(int? index = null) {
			object value = base.Value;
			if ((index != null) && (value is CompoundValue)) {
				// get the string values of the specified field
				value = ((CompoundValue)value).GetValue((int)index);
			}
			string[] result = null;
			if (value is CompoundValue) {
				CompoundValue cv = (CompoundValue)value;
				result = new string[cv.Count];
				for (int i = 0; i < cv.Count; i++) {
					if (cv[i] != null) {
						result[i] = cv[i].ToString();
					}
				}
			}
			else if (value != null) {
				result = new string[1];
				result[0] = value.ToString();
			}
			return result;
		}
		
		/// Set the value, optionally at the specified indices.
		public void SetValue(object value, int index = 0, int subIndex = 0) {
			// check if we have a compound value to hold the new value
			CompoundValue cv = base.Value as CompoundValue;
			if (cv == null) {
				if ((index == 0) && (subIndex == 0)) {
					// degenerate case: store the value directly
					base.Value = value;
					return;
				}
				// we need a CompoundValue, so create one to hold the value
				cv = new CompoundValue();
				if (base.Value != null) {
					// preserve the degenerate first value
					cv.Add(base.Value);
				}
				base.Value = cv;
			}
			// check if we have a CompoundValue to hold the value
			object atIndex = cv.GetValue(index);
			CompoundValue scv =  atIndex as CompoundValue;
			if (scv == null) {
				if (subIndex == 0) {
					// degenerate case: store the value directly
					cv.SetValue(index,value);
					return;
				}
				scv = new CompoundValue(cv);
				if (atIndex != null) {
					// preserve the degenerate first value
					scv.Add(atIndex);
				}
				cv.SetValue(index,scv);
			}
			scv.SetValue(subIndex, value);
		}

		/// Set the values, optionally at the specified index.
		/// @note other values (at the index) are removed
		public void SetValuesAsString(string[] values, int? index = null) {
			if (values == null) {
				throw new ArgumentNullException("values");
			}
			CompoundValue cv = base.Value as CompoundValue;
			if (cv == null) {
				// we need a CompoundValue, so create one to hold the values
				cv = new CompoundValue();
				base.Value = cv;
			}
			if (index == null) {
				// replace existing fields with the values
				cv.Clear();
				cv.AddRange(values);
			}
			else {
				// replace values of field 'index'
				// check if we have a CompoundValue to hold the value
				CompoundValue scv =  cv.GetValue((int)index) as CompoundValue;
				if (scv == null) {
					scv = new CompoundValue(cv);
					cv.SetValue((int)index,scv);
				}
				// replace existing subfields with the values
				scv.Clear();
				scv.AddRange(values);
			}
		}
	}

	///
	/// A keyed collection of directory of ItemObjects.
	///
	/// The directory has an internal dictionary for a fast lookup of items, based on their Identifier.
	/// Since the Identifier of an ItemObject is mutable, the update of the ItemObject.Identifier results in an update of the 
	/// associated Directory as well; the ItemObject holds a reference to the Dictionary for this.
	/// An ItemObject can only be in one directory.
	/// @see https://docs.microsoft.com/en-us/dotnet/api/system.collections.objectmodel.keyedcollection-2?view=netframework-4.5.2
	///
	public class Directory : System.Collections.ObjectModel.KeyedCollection<string,ItemObject> {
	
		/// The default constructor.
		/// The specified dictionary threshold 0 means that the internal Dictionary 
		/// is created the first time an object is added.
		public Directory() : base(null, 0) {
		}

		/// Create a new ItemObject and add it to the Dictionary.
		/// @param name the (display) name of the ItemObject
		/// @param id a unique identifier URI; by default a new UUID URI is generated 
		public ItemObject NewItem(string name = null, nl.nlsw.Identifiers.Uri id = null) {
			ItemObject result = new ItemObject(name,id);
			Add(result);
			return result;
		}
		
		/// Get the key of the ItemObject object.
		protected override string GetKeyForItem(ItemObject item) {
			// The Identifier is the key.
			return item.Identifier.ToString();
		}

		protected override void InsertItem(int index, ItemObject newItem) {
			if (newItem.Directory != null) {
				throw new ArgumentException("The item is already registered in a directory.",newItem.Name);
			}

			base.InsertItem(index, newItem);
			newItem.Directory = this;
		}

		/// Move the items from the other directory into this one.
		/// @post other will be empty
		/// @exception one of the imported items has a key that already exists
		public void MoveFrom(Directory other) {
			for (int i = other.Count - 1; i >= 0; i--) {
				ItemObject p = other[i];
				other.RemoveItem(i);
				Add(p);
			}
		}

		protected override void SetItem(int index, ItemObject newItem) {
			ItemObject replaced = Items[index];

			if (newItem.Directory != null) {
				throw new ArgumentException("The item is already registered in a directory.",newItem.Name);
			}

			base.SetItem(index, newItem);
			newItem.Directory = this;
			replaced.Directory = null;
		}

		protected override void RemoveItem(int index) {
			ItemObject removedItem = Items[index];

			base.RemoveItem(index);
			removedItem.Directory = null;
		}

		protected override void ClearItems() {
			foreach (ItemObject item in Items) {
				item.Directory = null;
			}
			base.ClearItems();
		}

		/// To be called from ItemObject.Identifier.set
		internal void ChangeKey(ItemObject item, string newKey) {
			base.ChangeItemKey(item, newKey);
		}
	}
	
	///
	/// The ItemObject class represents a named item with a unique identifier,
	/// that is collected in a Directory.
	///
	/// An ItemObject may have properties. Each ItemObject is registered in a Directory.
	///
	/// @note The name Item cannot be used if you want the class to have an indexer property.
	/// 		The .NET runtime uses the name "Item" for these properties, and this results
	/// 		in the compiler error "Item" member names cannot be the same as their
	/// 		enclosing type.
	/// @note The use of the name 'Thing' for this class is rejected, because we don't want
	/// 		the condition "Person is Thing" to be true.
	/// @see https://schema.org/Thing
	///
	public class ItemObject {
		/// The directory (keyed collection of items) that this ItemObject belongs to.
		private Directory _Directory = null;
		/// Unique identifier of the item, e.g. a urn:uuid
		private nl.nlsw.Identifiers.Uri _Identifier = null;
		/// Properties of the item
		private Properties _Properties = null;
		
		/// Get a property or the properties by case insensitive name
		[System.Xml.Serialization.XmlIgnore()]
		public object this[string name] {
			get {
				if (_Properties != null) {
					return _Properties[name];
				}
				return null;
			}
		}

		/// The directory that this ItemObject belongs to.
		[System.Xml.Serialization.XmlIgnore()]
		public Directory Directory {
			get { return this._Directory; }
			internal set { 
				this._Directory = value;
			}
		}

		public bool HasProperties {
			get { return (_Properties != null) && (_Properties.Count > 0); }
		}

		///
		/// The unique identifier of the ItemObject.
		/// The value should be a normalized Uri, such that a string
		/// comparison can be used for equality check.
		/// The Uri.Equals is not suited since e.q. a comparison of a mailto-uri (i.e. an
		/// e-mail address) will fail since UserInfo is not included in the Uri.Equals.
		/// A UUID is preferred as identifier.
		///
		/// The (string value) Identifier is used as key in the associated Directory.
		/// If the Identifier is changed, the Directory is automatically updated.
		/// In that case, an ArgumentException is thrown if the new value is null or an existing key.
		///
		[System.Xml.Serialization.XmlIgnore()]
		public nl.nlsw.Identifiers.Uri Identifier {
			get { return this._Identifier; } 
			set {
				if (Directory != null) {
					// @todo change Identifier comparison from string to the Identifier object itself
					Directory.ChangeKey(this, value == null ? null : value.ToString());
				}
				this._Identifier = value;
			}
		}

		/// Get an icon character representing the (type of) ItemObject.
		/// @note to represent any Unicode char, you need a string in C#,
		/// 	since a char is only 16-bit
		[System.Xml.Serialization.XmlIgnore()]
		public virtual string IconChar {
			get { return "\u2022"; }	// BULLET
		}

		[System.Xml.Serialization.XmlIgnore()]
		public string Name { get; set; }
		
		[System.Xml.Serialization.XmlIgnore()]
		public Properties Properties {
			get {
				if (_Properties == null) {
					_Properties = new Properties();
				}
				return _Properties;
			}
		}


		/// Default and initializing constructor
		/// @param name the (display) name of the ItemObject
		/// @param id a unique identifier URI; by default a new UUID URI is generated 
		public ItemObject(string name = null, nl.nlsw.Identifiers.Uri id = null) {
			if (id == null) {
				// create a new UUID URI
				id = nl.nlsw.Identifiers.UrnUri.NewUuidUrnUri();
			}
			this.Identifier = id;
			this.Name = name;
		}

		/// Get properties by name, and (optionally) attribute name and value.
		public Properties GetProperties(string name, string attrName = null, string attrValue = null) {
			if (_Properties != null) {
				return _Properties.Get(name,attrName,attrValue);
			}
			return null;
		}

		/// Get the first property by name, and (optionally) attribute name and value.
		public Property GetProperty(string name, string attrName = null, string attrValue = null) {
			if (_Properties != null) {
				return _Properties.GetProperty(name,attrName,attrValue);
			}
			return null;
		}

		public override string ToString() {
			return (string.IsNullOrEmpty(Name) ? (Identifier == null ? null : Identifier.ToString()) : Name);
		}
	}	

	/// A stack of ItemObjects, typically used when processing nested sets of ItemObjects.
	public class ItemStack : System.Collections.Generic.Stack<ItemObject> {
	}

	/// A Property of an ItemObject.
	///
	/// Class of attributed Name=Value objects, holding a property of an ItemObject.
	/// The value of the property can be formatted in different ways based on a IFormatProvider.
	///
	public class Property : IFormattable {
		private Attributes _attrs = null;
		private object _Value;
		/// the name of the attribute that holds the group name of the property
		public static readonly string GroupNameAttribute = ".group";
		
		/// The name of the group that the property belongs to.
		public string GroupName {
			get { return GetAttribute(GroupNameAttribute); }
			set { SetAttribute(GroupNameAttribute, value); }
		}

		/// The attributes of the property
		public Attributes Attributes { 
			get {
				if (_attrs == null) {
					_attrs = new Attributes();
				}
				return _attrs;
			}
		}
		
		/// Get or set an attribute of the property.
		public string this[string name] {
			get { return GetAttribute(name); }
			set { SetAttribute(name, value); }
		}
		
		/// Get an icon character representing the (type of) Property.
		/// @note to represent any Unicode char, you need a string in C#,
		/// 	since a char is only 16-bit
		public virtual string IconChar {
			// U+214A PROPERTY LINE
			// (think of the symbol as indicating the start of another property)
			get { return "\u214A"; }
		}

		/// The name of the property
		public string Name { get; set; }

		/// The value of the property
		public virtual object Value {
			get { return _Value; } 
			set { _Value = value; }
		}

		/// The type of the value
		public virtual string ValueType {
			get { return "text"; }
		}

		public bool HasAttributes {
			get { return (_attrs != null) && (_attrs.Count > 0); }
		}
		
		/// Class constructor
		static Property() {
		}

		/// Default constructor
		public Property() {
		}

		/// Initializing Constructor
		public Property(string name, object value = null) {
			this.Name = name;
			this.Value = value;
		}

		/// Get the value of the specified attribute. If not present, the default value is returned.
		/// If the attribute has multiple values, they are returned as a comma-separated list, without proper enquoting.
		public string GetAttribute(string name, string defaultValue = null) {
			if (_attrs != null) {
				return _attrs.Get(name) ?? defaultValue;
			}
			return defaultValue;
		}
		
		/// Test whether the property has an attribute with the specified name and (optionally) value combination.
		/// Name comparison is case-insensitive, value comparison is case-sensitive.
		public bool HasAttribute(string name, string value = null) {
			if (_attrs != null) {
				string[] values = _attrs.GetValues(name);
				if (values != null) {
					return (value == null) || (System.Array.IndexOf(values,value) >= 0);
				}
			}
			return false;
		}
		
		/// Check if this property has the specified name.
		/// Performs a case-insensitive compare.
		public bool HasName(string name) {
			return (String.Compare(Name,name,StringComparison.OrdinalIgnoreCase) == 0);
		}

		/// Test whether the attribute name represents an internal, hidden attribute.
		/// A name represents a hidden attribute if:
		/// - the name is null or empty, indicating no attribute, which is hidden by its nature
		/// - it starts with a FULL STOP, indicating an internal attribute
		public virtual bool IsHiddenAttribute(string name) {
			return string.IsNullOrEmpty(name) || name.StartsWith(".",StringComparison.Ordinal);
		}

		/// Set the value of the specified attribute.
		public void SetAttribute(string name, string value) {
			Attributes.Set(name,value);
		}

		/// Object.ToString()
		/// To be used for general display of the property
		/// By default, return Value.ToString()
		public override string ToString() {
			return Value == null ? null : Value.ToString();
		}
		
		/// IFormattable.ToString()
		/// To be used for (formatted) output of the property value.
		/// By default, returns Value.ToString()
		public virtual string ToString(string format, IFormatProvider formatProvider) {
			return Value == null ? null : Value.ToString();
		}
	}
	
	/// A list of properties
	/// The list may contain multiple properties with the same name.
	public class Properties : List<Property> {
	
		/// Get a property or the properties by case insensitive name
		public object this[string name] {
			get {
				Property first = null;
				Properties list = null;
				foreach (Property prop in this) {
					if (prop.HasName(name)) {
						if (first == null) {
							first = prop;
						}
						else {
							if (list == null) {
								list = new Properties();
								list.Add(first);
							}
							list.Add(prop);
						}
					}
				}
				return (list == null ? (object)first : (object)list);
			}
		}

		/// Add a property
		/// @deprecated use a factory method API for type specific properties
		public Property AddProperty(string name, object value) {
			Property prop = new Property(name,value);
			Add(prop);
			return prop;
		}

		/// Get the properties by (optionally) case insensitive name,
		/// and (optionally) case insensitive attribute name,
		/// and (optionally) case sensitive attribute value.
		/// E.g. get all properties with a specific attribute (value) by setting name to null.
		public Properties Get(string name, string attrName = null, string attrValue = null) {
			Properties result = null;
			foreach (Property prop in this) {
				if (((name == null) || prop.HasName(name))
				&& ((attrName == null) || prop.HasAttribute(attrName,attrValue))) {
					if (result == null) {
						result = new Properties();
					}
					result.Add(prop);
				}
			}
			return result;
		}
		
		/// Get the first property by (optionally) case insensitive name,
		/// and (optionally) case insensitive attribute name,
		/// and (optionally) case sensitive attribute value.
		public Property GetProperty(string name, string attrName = null, string attrValue = null) {
			foreach (Property prop in this) {
				if (((name == null) || prop.HasName(name))
				&& ((attrName == null) || prop.HasAttribute(attrName,attrValue))) {
					return prop;
				}
			}
			return null;
		}
		
		/// Remove all properties with the specified name
		public void RemoveProperty(string name) {
			for (int i = Count-1; i >= 0; i--) {
				if (this[i].HasName(name)) {
					Remove(this[i]);
				}
			}
		}
	}
	
	/// Base class for reading ItemObjects from a stream
	public class Reader {
		/// declare the stack used during parsing (nested)  items
		private ItemStack _ItemStack = new nl.nlsw.Items.ItemStack();
		/// the default encoding of the source text
		private System.Text.Encoding _DefaultEncoding;
		/// the buffer for unfolding content lines
		private System.Text.StringBuilder _ContentLine = new System.Text.StringBuilder();
		/// the buffer for lines to process when no format is known yet
		private List<string> _LineCache;

		/// Buffer for unfolding the current content line
		public System.Text.StringBuilder ContentLine {
			get { return _ContentLine; }
		}
		
		/// The target directory for read ItemObjects
		public Directory CurrentDirectory { get; set; }

		/// The current source encoding
		public System.Text.Encoding CurrentEncoding {
			get {
				System.IO.StreamReader sr = this.TextReader as System.IO.StreamReader;
				if (sr != null) {
					// the StreamReader may have detected another encoding than the default
					return sr.CurrentEncoding;
				}
				return _DefaultEncoding;
			}
		}

		/// The current ItemObject
		public ItemObject CurrentItem {
			get { return (_ItemStack.Count == 0) ? null : _ItemStack.Peek(); }
		}
		
		/// The default Encoding to use
		public System.Text.Encoding DefaultEncoding {
			get { return _DefaultEncoding; }
		}

		/// The number of files read
		public int FileCount { get; set; }

		/// The current file being read
		public System.IO.FileSystemInfo FileInfo { get; set; }
		
		/// The name of the file or other source being read
		public string FileName {
			get {
				if (FileInfo != null) {
					return FileInfo.FullName;
				}
				if (TextReader != null) {
					System.IO.StreamReader sr = TextReader as System.IO.StreamReader;
					if (sr != null) {
						if (sr.BaseStream is System.IO.FileStream) {
							return ((System.IO.FileStream)sr.BaseStream).Name;
						}
						if (sr.BaseStream is System.Net.Sockets.NetworkStream) {
							// no more info retrievable
							return "<networkstream>";
						}
					}
					return "<stream>";
				}
				return "<pipe>";
			}
		}
		
		/// Check if the reader has cached lines
		public bool HasCachedLines {
			get { return _LineCache != null && _LineCache.Count > 0; }
		}
		
		/// Check if the reader has a content line read
		public bool HasContentLine {
			get { return _ContentLine.Length > 0; }
		}
		
		/// The buffer for lines to process when no format is known yet
		public List<string> LineCache {
			get {
				if (_LineCache == null) {
					_LineCache = new List<string>();
				}
				return _LineCache;
			}
		}

		/// The number of ItemObjects read
		public int ItemCount { get; set; }

		/// Next line must be joined with the previous one,
		/// as part of QuotedPrintable encoded data
		public bool QuotedPrintableFolding { get; set; }
		
		/// To keep track of the ItemObject nesting
		public ItemStack Stack {
			get { return _ItemStack; }
		}
		
		/// The TextReader to use for reading
		public System.IO.TextReader TextReader { get; set; }
		
		/// Default constructor
		public Reader() {
			_DefaultEncoding = System.Text.Encoding.UTF8;
		}

		/// Initializing constructor
		public Reader(System.Text.Encoding defaultEncoding = null) {
			_DefaultEncoding = defaultEncoding ?? System.Text.Encoding.UTF8;
		}

		///
		/// Decode a string containing a compound value, i.e. delimited fields, optionally with nested sub-fields.
		/// In addition, or alternatively, escaped characters can be unescaped.
		/// Escaped delimiters are unescaped in the returned result automatically.
		///
		/// Example use cases:
		/// - the data string does not contain any of the delimiters: the input string is returned
		///
		/// - the data string only contains escaped delimiters or other escape sequences: the unescaped string is returned
		///   @example "simple text string\, that may contain a delimiter like \\" => "simple text string, that may contain a delimiter like \"
		///
		/// - a string containing delimited list members (a List<String> is returned with the members; actually a CompundValue, since that is also a List)
		///   @example "member 1,member\, with path \\,member 3" => ( "member 1", "member, with path \", "member 3" )
		/// 
		/// - a string containing delimited fields with simple string content or a list of members (a List<Object> is returned with the fields, either a String or a List<String>)
		///   @example "field 1;field2\, member 1, field2\, member 2;field 3" => ( "field 1", ( "field 2, member1", "field 2, member 2"), "field 3" )
		/// 
		/// Example application is decoding the vCard property value.
		///
		/// @param data the input data string
		/// @param delimiters the first character in the array must be the escape character; subsequent characters are the ordered delimiters of the nested fields
		/// @param replacements the additional escape sequences that need to be decoded; the delimiters are replaced automatically; a non-specified escape sequence
		///			is left as-is.
		/// @return a System.String or a nl.nlsw.Items.CompoundValue
		/// 
		public static object DecodeCompoundValue(string data, char[] delimiters, Dictionary<char,string> replacements = null) {
			int position = (delimiters != null) ? data.IndexOfAny(delimiters) : -1;
			if (position == -1) {
				// no delimiters specified or present, return the input string
				return data;
			}
			System.Text.StringBuilder sb = new System.Text.StringBuilder();
			CompoundValue cv = null;
			string replacement;
			int start = 0;
			
			for (; (position = data.IndexOfAny(delimiters, position)) != -1; start = position) {
				sb.Append(data,start, position - start);
				start = position;
				char delim = data[position++];
				int delindex = Array.IndexOf<char>(delimiters,delim);
				if (delindex < 0) {
					throw new InvalidOperationException("found compound value delimiter must be in the array of delimiters");
				}
				else if (delindex == 0) {
					// the EscapeCharacter found
					if (position < data.Length) {
						if (Array.IndexOf<char>(delimiters,data[position]) != -1) {
							// copy the escaped delimiter
							sb.Append(data[position]);
						}
						else if ((replacements != null) && replacements.TryGetValue(data[position],out replacement)) {
							// it is one of the replacements
							sb.Append(replacement);
						}
						else {
							// other character: copy both (keep original text) and continue
							sb.Append(data,start,2);
						}
						position++;
					}
					else {
						// EscapeChar at end of data: copy and finish
						sb.Append(delim);
					}
				}
				else {
					// delimiter is one of the compound field delimiters
					if (cv == null) {
						// start a compound value for this delimiter
						cv = new CompoundValue();
					}
					int depth = delindex - 1;
					if (depth == cv.Depth) {
						// sibling field parsed
						cv.Add(sb.ToString());
						sb.Clear();
					}
					else if (depth > cv.Depth) {
						while (depth > cv.Depth) {
							// increase level
							CompoundValue child = new CompoundValue(cv);
							cv.Add(child);
							cv = child;
						}
						cv.Add(sb.ToString());
						sb.Clear();
					}
					else {
						cv.Add(sb.ToString());
						sb.Clear();
						while (depth < cv.Depth) {
							if (cv.Parent == null) {
								throw new FormatException("stack underflow during compound value parsing");
							}
							cv = cv.Parent;
						}
					}
				}
			}
			if (start < data.Length) {
				sb.Append(data,start, data.Length - start);
			}
			if (cv != null) {
				if (sb.Length > 0) {
					cv.Add(sb.ToString());
					sb.Clear();
				}
				while (cv.Parent != null) {
					cv = cv.Parent;
				}
				return cv;
			}
			// simply return the unescaped string, no compound value present
			return sb.ToString();
		}

		/// Decode Base64 encoded text
		/// @see https://en.wikipedia.org/wiki/Base64
		public static string DecodeBase64Text(string data, System.Text.Encoding encoding) {
			// convert base64 text to array
			byte[] bytes = System.Convert.FromBase64String(data);
			// convert bytes to text
			return encoding.GetString(bytes);
		}
					
		///
		/// Decode Base64 encoded text recursively in a list
		/// 
		public static System.Collections.IList DecodeBase64Text(System.Collections.IList data, System.Text.Encoding encoding) {
			for (int i = 0; i < data.Count; i++) {
				if (data[i] is string) {
					data[i] = DecodeBase64Text((string)(data[i]), encoding);
				}
				else if (data[i] is System.Collections.IList) {
					data[i] = DecodeBase64Text((System.Collections.IList)(data[i]), encoding);
				}
			}
			return data;
		}

		/// Decode Quoted-Printable text
		/// 
		/// @see https://en.wikipedia.org/wiki/Quoted-printable
		/// @see https://stackoverflow.com/questions/2226554/c-class-for-decoding-quoted-printable-encoding
		public static string DecodeQuotedPrintable(string data, System.Text.Encoding encoding) {
			int position = data.IndexOf('=');
			if (position == -1) {
				// no fields, members, or escaped chars present, return the input string
				return data;
			}
			System.Text.StringBuilder result = new System.Text.StringBuilder(data.Length);
			System.Collections.Generic.List<byte> bytes = new System.Collections.Generic.List<byte>();
			int start = 0;
			for (start = 0; ((position = data.IndexOf('=', position)) != -1) && (position + 2 < data.Length); start = position) {
				result.Append(data, start, position - start);

				do {
					position++;
					if ((data[position] == '\r') && (data[position + 1] == '\n')) {
						// unfold soft line breaks: remove "=\r\n" from data
						position += 2;
					}
					else {
						try {
							// hex-convert a byte
							bytes.Add(System.Convert.ToByte(data.Substring(position, 2), 16));
						}
						catch (Exception ex) {
							throw new Exception(data.Substring(position, 2),ex);
						}
						position += 2;
					}
				} while ((position < data.Length) && (data[position] == '='));
				if (bytes.Count > 0) {
					// convert bytes to text
					string equivalent = encoding.GetString(bytes.ToArray());
					result.Append(equivalent);
					bytes.Clear();
				}
			}
			if (start < data.Length) {
				result.Append(data, start, data.Length - start);
			}
			return result.ToString();
		}
		
		/// Decode Quoted-Printable text recursively in a list
		/// 
		public static System.Collections.IList DecodeQuotedPrintable(System.Collections.IList data, System.Text.Encoding encoding) {
			for (int i = 0; i < data.Count; i++) {
				if (data[i] is string) {
					data[i] = DecodeQuotedPrintable((string)(data[i]), encoding);
				}
				else if (data[i] is System.Collections.IList) {
					data[i] = DecodeQuotedPrintable((System.Collections.IList)(data[i]), encoding);
				}
			}
			return data;
		}
	}

	///
	/// Base class for writing ItemObjects.
	/// Writing to string is supported via the StringWriter base class.
	/// Creating an XmlDocument is also supported.
	/// @todo specialize into TextWriter and XmlWriter ?
	public class Writer : System.IO.StringWriter, System.IFormatProvider, System.ICustomFormatter {
		/// The ItemObject being written
		private ItemObject _CurrentItem;
		/// The current node to add content to
		private System.Xml.XmlNode _CurrentNode;
		/// The current XmlDocument being written
		private System.Xml.XmlDocument _Document;
		/// The XML namespace manager associated with the current document
		private System.Xml.XmlNamespaceManager _NamespaceManager;
		/// Hashtable of XML namespaces
		private System.Collections.Hashtable _Namespaces;

		/// The culture to use during writing.
		/// @todo distinguish from the iFormatProvider of the StringWriter
		public System.Globalization.CultureInfo CultureInfo { 
			get; set;
		}
		
		/// The current XmlNode to write to.
		/// By default of a specific node set the DocumentElement of the Document is returned.
		public System.Xml.XmlNode CurrentNode { 
			get {
				if (_CurrentNode == null && Document != null) {
					return Document.DocumentElement;
				}
				return _CurrentNode;
			}
			set { _CurrentNode = value; }
		}

		/// The ItemObject being written
		public ItemObject CurrentItem {
			get { return _CurrentItem; }
			set {
				if (value != _CurrentItem) {
					if (_CurrentItem != null) {
						// auto-increment ItemCount
						ItemCount++;
					}
				}
				_CurrentItem = value;
			}
		}

		/// The XmlDocument to write to.
		public System.Xml.XmlDocument Document { 
			get { return _Document; }
			set {
				if (_Document != value) {
					_Document = value;
					// refresh the associated namespacemanager on next get
					_NamespaceManager = null;
				}
			}
		}

		public override System.Text.Encoding Encoding { 
			get { return System.Text.Encoding.UTF8; }
		}
		
		/// The current property (value) requires Base64 encoding,
		/// e.g. because of non-ASCII characters present
		public bool EncodeBase64 { get; set; }

		/// The XmlNamespaceManager needed for SelectNodes() and SelectSingleNode().
		public System.Xml.XmlNamespaceManager NamespaceManager { 
			get {
				if ((_NamespaceManager == null) && (_Document != null)) {
					// create the manager
					_NamespaceManager = new XmlNamespaceManager(_Document.NameTable);
					if (_Namespaces != null) {
						// fill with the registered namespaces
						foreach (DictionaryEntry entry in _Namespaces) {
							_NamespaceManager.AddNamespace(entry.Key.ToString(), entry.Value.ToString());
						}
					}
				}
				return _NamespaceManager;
			}
		}

		/// The XML namespaces needed for SelectNodes() and SelectSingleNode().
		public System.Collections.Hashtable Namespaces { 
			get { return _Namespaces; }
			set {
				if (_Namespaces != value) {
					_Namespaces = value;
					// clear the NamespaceManager to force an update on next get
					_NamespaceManager = null;
				}
			}
		}
		
		/// Keep track of the number of ItemObjects written
		public int ItemCount { get; set; }
		
		/// Get the Position in the underlying StringBuilder
		public int Position {
			get { return GetStringBuilder().Length; }
		}

		/// Default constructor
		/// Uses the invariant culture, for persistent storage.
		public Writer() : base(System.Globalization.CultureInfo.InvariantCulture) {
		}
		
		/// Initializing constructor
		/// Uses the invariant culture, for persistent storage.
		public Writer(IFormatProvider provider) : base(provider) {
		}

		/// Encode text as Base64 encoded text
		/// @see https://en.wikipedia.org/wiki/Base64
		public static string EncodeBase64Text(string data, System.Text.Encoding encoding) {
			// get the byte representation of the text data, for the given encoding
			byte[] bytes = encoding.GetBytes(data);
			// convert binary data to base64 text string
			return System.Convert.ToBase64String(bytes);
		}

		///
		/// Flushes the contents of the internal string builder to the specified file,
		/// and clears the string builder.
		/// The file is written in UTF-8 wihout BOM.
		///
		public void FlushToFile(string filename) {
			System.Text.StringBuilder sb = GetStringBuilder();
			// write UTF8 text without BOM
			System.IO.File.WriteAllText(filename, sb.ToString());
			// clear the buffer
			sb.Clear();
		}
		
		///
		/// Flushes the contents of the internal string builder to a string,
		/// and clears the string builder.
		/// @return the content string
		///
		public string FlushToString() {
			System.Text.StringBuilder sb = GetStringBuilder();
			string result = sb.ToString();
			// clear the buffer
			sb.Clear();
			return result;
		}

		/// Format a Property (value)
		/// ICustomFormatter.Format()
		public virtual string Format(string format, object arg, IFormatProvider formatProvider) {
			return null;
		}
  
		/// IFormatProvider.GetFormat()
		public virtual object GetFormat(Type formatType) {
			return this;
		}

		///
		/// Perform line folding on the (possibly long) line in the string buffer (starting at startIndex),
		/// by inserting a LineBreak after each section of the line of which the byte representation of the 
		/// encoding counts OctetsPerLine bytes or less.
		/// The string buffer is supposed to contain a single line, i.e. any newline characters already present
		/// are handled as normal characters.
		/// @param LineBreakLineChars the number of characters of the LineBreak to include in the next line
		///
		public void OctetBasedLineFolding(int startIndex = 0,
				int OctetsPerLine = 75, string LineBreak = "\r\n ", int LineBreakLineChars = 1) {
			System.Text.StringBuilder sb = GetStringBuilder();
			int maxBytesPerChar = Encoding.GetMaxByteCount(1);
			if ((startIndex < 0) || (startIndex >= sb.Length)) {
				throw new ArgumentOutOfRangeException("startIndex","startIndex must be in the string buffer range");
			}
			if (OctetsPerLine < maxBytesPerChar) {
				throw new ArgumentOutOfRangeException("OctetsPerLine","OctetsPerLine seems rather small");
			}
			// check if line folding may be necessary
			if ((maxBytesPerChar * (sb.Length - startIndex)) > OctetsPerLine) {
				// determine the chunk size: we take as muchs chars as possible, assume 1 byte per char
				int lineChunkOctets = OctetsPerLine;
				// copy the string buffer contents in a consecutive array
				char[] chars = new char [sb.Length - startIndex];
				sb.CopyTo(startIndex,chars,0,sb.Length - startIndex);
				for (int start = 0, linestart = startIndex; start < chars.Length; ) {
					// determine the actual chunk size (limit to remaining number of chars)
					int count = Math.Min(lineChunkOctets,chars.Length - start);
					// count the bytes of the chunk of the line
					int numBytes = Encoding.GetByteCount(chars, start, count);
					// reduce the chunk while still too many bytes needed
					while ((count > 0) && (numBytes > lineChunkOctets)) {
						// reduce number of characters until number of bytes fit
						numBytes = Encoding.GetByteCount(chars, start, --count);
					}
					// do we need to insert a LineBreak?
					if ((chars.Length > (start + count)) && (count > 0)) {
						// yes
						sb.Insert(linestart + count,LineBreak);
						// account the LineBreak in the line position
						linestart += LineBreak.Length;
						// the next line is already started with some chars from the line break (those chars have 1 byte per char).
						lineChunkOctets = OctetsPerLine - LineBreakLineChars;
					}
					else {
						// we are done
						break;
					}
					start += count; linestart += count;
				}
			}
		}
	}
}
