//	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
//	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
//
/// @file nl.nlsw.Document.cs
/// @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later

using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Collections.ObjectModel;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;

///
/// Utility classes for the processing of documents.
///
/// @author Ernst van der Pols
/// @date 2019-10-26
/// @requires .NET Framework 4.5
///
namespace nl.nlsw.Document {

	/// Utility class for operations on documents or file(name)s
	public class Utility {
		/// A regex for matching and replacing '{}'-delimited parameters in strings like a filename.
		/// Typically, the replacement text depends on the value of the parameter being empty or not.
		public static readonly Regex PathMacroRegex = new Regex(@"{((?<pre>[^<\|}]+)<)?(?<key>[^>\|}]+)(>(?<post>[^\|}]+))?(\|(?<empty>[^}]*))?}",
			RegexOptions.Compiled|RegexOptions.CultureInvariant);

		/// A regex for matching or replacing series of one or more white space characters.
		public static readonly Regex ReplaceWhiteSpaceRegex = new Regex(@"\s+",
			RegexOptions.Compiled|RegexOptions.CultureInvariant);
		
		/// A regex for inserting hyphens in a CamelCased) > Camel-Cased > camel-cased word
		public static readonly Regex HyphenateCamelCaseRegex = new Regex(@"([a-z])([A-Z])",
			RegexOptions.Compiled|RegexOptions.CultureInvariant);
		
		public static string ConvertCamelCaseToHyphenated(string name) {
			return HyphenateCamelCaseRegex.Replace(name, "$1-$2").ToLower();
		}

		/// U+1F511
		public static string Key = "\U0001F511";
	}
	
}
