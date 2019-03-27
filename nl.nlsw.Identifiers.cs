//	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
//	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
//
// @file nl.nlsw.Identifiers.cs
//

using System;
using System.Collections;
using System.Collections.Specialized;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

///
/// Classes of Uniform Resource Identifiers.
///
/// @author Ernst van der Pols
/// @date 2019-03-19
/// @requires .NET Framework 4.5
///
namespace nl.nlsw.Identifiers {

	///
	/// A Uniform Resource Identifier for Geographic Locations
	///
	/// @see https://tools.ietf.org/html/rfc5870
	/// @see https://en.wikipedia.org/wiki/Geo_URI_scheme
	/// @see http://geouri.org/
	///
	public class GeoUri : ParameterizedUri {
		public static readonly string UriSchemeGeo = "geo";
		/// Department of Defence World Geodetic System 1984
		public const string WGS84 = "wgs84";
		/// RFC5780 compliant reg-ex for a GeoUri
		/// @note You cannot capture the individual pname[=pvalue] pairs at once
		public static Regex GeoRegex = new Regex(@"^geo:(?<lat>[\-]?\d+(\.\d+)?),(?<lon>[\-]?\d+(\.\d+)?)(,(?<alt>[\-]?\d+(\.\d+)?))?(;crs=(?<crs>[A-Za-z0-9\-]+))?(;u=(?<unc>\d+(\.\d+)?))?(;(?<par>(?<pname>[A-Za-z0-9\-]+)(=(?<pvalue>([!\$&-+\-\.0-:A-Z\[\]_a-z~]|%[0-9A-F]{2})+))?))*",
			RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
		/// These parameters are specifically handled on compare
		public static readonly string[] ExcludeKnownParameters = { "crs","unc" };

		private string _CRS;
		private double? _Altitude;
		private double _Latitude;
		private double _Longitude;
		private double? _Uncertainty;

		/// The altitude in meter above/below sea level
		public double? Altitude {
			get { return _Altitude; }
		}

		/// The used coordinate reference system
		public string CoordinateReferenceSystem {
			get { return _CRS ?? WGS84; }
		}

		/// The latitude in decimal degrees
		public double Latitude {
			get { return _Latitude; }
		}

		/// The longitude in decimal degrees
		public double Longitude {
			get { return _Longitude; }
		}
	
		/// The Uncertainty in meter around the coordinate point in each dimension
		/// with which the location is known. Might by not specified or unknown (null).
		public double? Uncertainty {
			get { return _Uncertainty; }
		}

		/// Initializing constructor
		public GeoUri(double latitude, double longitude, double? altitude = null, double? uncertainty = null, string crs = WGS84)
			: base(String.Format("{0}:{1},{2}{3}{4}{5}",UriSchemeGeo,latitude,longitude,
				((altitude != null) ? String.Format(",{0}",altitude) : null),
				((!String.IsNullOrEmpty(crs) && crs != WGS84) ? String.Format(";crs={0}",crs.ToLower()) : null),
				((uncertainty != null) ? String.Format(";u={0}",uncertainty) : null))
				)
		{
			ParseGeoScheme(OriginalString);
		}
		
		/// Conversion constructor from string
		public GeoUri(string uri) : base(uri) {
			ParseGeoScheme(OriginalString);
		}

		/// Conversion constructor from base
		/// @note The combining constructor can be used with an empty relative uri to get the result.
		public GeoUri(System.Uri uri) : base(uri,(string)null) {
			ParseGeoScheme(OriginalString);
		}
		
		public override int GetHashCode() {
			// a simpler solution than using the Uri implementation
			return StringComparer.InvariantCultureIgnoreCase.GetHashCode(OriginalString);
			// return base.GetHashCode();
		}
		
		///
		/// Equals
		///
		/// Overrides default function (in Uri class)
		///
		/// @pre <comparand> is an object of class GeoUri, Uri, or String
		///
		/// @return true if objects have the same value, else false
		/// @exception none
		///
		public override bool Equals(object comparand) {
			if ((object)comparand == null) {
				return false;
			}
			if ((object)this == (object)comparand) {
				return true;
			}

			GeoUri other = comparand as GeoUri;

			//
			// we allow comparisons of Uri and String objects only. If a string
			// is passed, convert to GeoUri. This is inefficient, but allows us to
			// canonicalize the comparand, making comparison possible
			//
			if ((object)other == null) {
				Uri u = comparand as Uri;
				string s = ((object)u != null) ? u.ToString() : (comparand as string);
				if ((object)s == null) {
					return false;
				}
				Match m = GeoRegex.Match(s);
				if (!m.Success) {
					return false;
				}
				// the string or Uri -is- a geo uri: create one (but catch exceptions)
				try {
					other = new GeoUri(s);
				}
				catch (Exception) {
					return false;
				}
			}
			// apply the RFC5870 comparison rules
			if (String.Compare(CoordinateReferenceSystem,other.CoordinateReferenceSystem,StringComparison.OrdinalIgnoreCase) != 0) {
				return false;
			}
			if (Latitude != other.Latitude || Altitude != other.Altitude || Uncertainty != other.Uncertainty) {
				return false;
			}
			if (CoordinateReferenceSystem == WGS84) {
				double lat = Latitude;
				if (Latitude != 90.0 && Latitude != -90.0) {
					if (Longitude != other.Longitude) {
						// this should never happen, since we have normalized the Longitude on creation
						if ((Math.Abs(Longitude) != 180.0) || (Math.Abs(other.Longitude) != 180.0)) {
							return false;
						}
					}
				}
			}
			else if (Longitude != other.Longitude) {
				return false;
			}
			// match additional parameters (with "binary" value compare)
			if (!HasEqualParameters(other,ExcludeKnownParameters,StringComparison.Ordinal)) {
				return false;
			}
			return true;
		}
		
		/// Parse the string for decoding the GEO URI scheme.
		/// @exception UriFormatException in case the scheme and string format does not comply
		/// @exception ArgumentOutOfRangeException in case any of the geo-properties is out of range
		private void ParseGeoScheme(string uri) {
			Match m = GeoRegex.Match(uri);
			if (!m.Success || (Scheme != UriSchemeGeo)) {
				Exception e = new UriFormatException("not a 'geo:' URI");
				e.Data.Add("uri",uri);
				throw e;
			}
			if (m.Groups["crs"].Success) {
				_CRS = m.Groups["crs"].Value.ToLower();
			}
			_Latitude = Convert.ToDouble(m.Groups["lat"].Value, CultureInfo.InvariantCulture);
			_Longitude = Convert.ToDouble(m.Groups["lon"].Value, CultureInfo.InvariantCulture);
			if (m.Groups["alt"].Success) {
				_Altitude = Convert.ToDouble(m.Groups["alt"].Value, CultureInfo.InvariantCulture);
			}
			if (m.Groups["unc"].Success) {
				_Uncertainty = Convert.ToDouble(m.Groups["unc"].Value, CultureInfo.InvariantCulture);
				if (_Uncertainty < 0) {
					throw new ArgumentOutOfRangeException("uncertainty", m.Groups["unc"].Value);
				}
			}
			if (m.Groups["par"].Success) {
				ParseParameterCaptures(m.Groups["par"].Captures);
			}
			if (CoordinateReferenceSystem == WGS84) {
				if ((_Latitude < -90.0) || (_Latitude > 90.0)) {
					throw new ArgumentOutOfRangeException("latitude", m.Groups["lat"].Value);
				}
				// first test user input
				if ((_Longitude < -180.0) || (_Longitude > 180.0)) {
					throw new ArgumentOutOfRangeException("longitude", m.Groups["lon"].Value);
				}
				// normalize longitude in case of Pole-location
				if (_Latitude == 90.0 || _Latitude == -90.0) {
					_Longitude = 0.0;
				}
			}
		}

		///
		/// Tries to convert the specified URI string to a GEO URI
		public static bool TryCreate(string uriString, out GeoUri uri) {
			try {
				uri = new GeoUri(uriString);
			}
			catch (Exception) {
				uri = null;
				return false;
			}
			return true;
		}

		public static bool TryCreate(out GeoUri uri, double latitude, double longitude, double? altitude = null, double? uncertainty = null, string crs = WGS84) {
			try {
				uri = new GeoUri(latitude,longitude,altitude,uncertainty,crs);
			}
			catch (Exception) {
				uri = null;
				return false;
			}
			return true;
		}
	}

	///
	/// A Uniform Resource Identifier for addressing Internet mail resources.
	///
	/// The 'mailto' URI scheme is used to identify resources that are reached using Internet mail, e.g. a mailbox.
	/// In its simplest form, a 'mailto' URI contains an Internet mail address.  For interactions that require
	/// message headers or message bodies to be specified, the 'mailto' URI scheme also allows providing mail
	/// header fields and the message body.
	/// 
	/// @note Althoug the mailto-URI has parameters in the form of header fields, the MailtoUri class is not
	/// 	a ParameterizedUri. The header fields are supported by the Query parameters of the URI Generic Syntax.
	///
	/// @note The scope of MailtoUri currently is only the support of a single mail address.
	///
	/// @see https://tools.ietf.org/html/rfc6068
	///
	public class MailtoUri : Uri {
		// public static readonly string UriSchemeMailto = "mailto";
		/// match a single internet email address
		/// atext = [!#-'\*\+\-/-9=\?A-Z\^-~]
		/// qtext = printables-excl-'\' | obs-qtext (obs-qtext laten we weg)
		/// local = ([atext]+ (. [atext]+)*) | ("([!#-\[\]-~]|(\\[\x21-\x7E\t ]))*")
		public static readonly Regex EmailAddressRegex = new Regex(@"^(?<local>(?<atom>[!#-'\*\+\-/-9=\?A-Z\^-~]+(\.[!#-'\*\+\-/-9=\?A-Z\^-~]+)*)|(?<qs>\x22([!#-\[\]-~]|(\\[\x21-\x7E\t ]))*\x22))@(?<domain>(?<atom>[!#-'\*\+\-/-9=\?A-Z\^-~]+(\.[!#-'\*\+\-/-9=\?A-Z\^-~]+)*)|(\[[!-Z\^-~]*\]))",
			RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
		/// RFC6068 compliant reg-ex for a MailtoUri (partly)
		public static readonly Regex MailtoRegex = new Regex(@"^mailto:(?<local>(?<latom>[!#-'\*\+\-/-9=\?A-Z\^-~]+(\.[!#-'\*\+\-/-9=\?A-Z\^-~]+)*)|(?<qs>\x22([!#-\[\]-~]|(\\[\x21-\x7E\t ]))*\x22))@(?<domain>(?<datom>[!#-'\*\+\-/-9=\?A-Z\^-~]+(\.[!#-'\*\+\-/-9=\?A-Z\^-~]+)*)|(\[[!-Z\^-~]*\]))",
			RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);

		/// The (unquoted) local part of the mail address
		private string _LocalPart;
		/// The domain of the mail address
		private string _Domain;
		
		/// The mail address
		public string Address {
			get { 
				return String.Concat(LocalPart,"@",Authority);
			}
		}

		/// The (unquoted?) local part of the mail address
		public string LocalPart {
			get { return _LocalPart; }
		}

		/// The domain of the mail address
		public string Domain {
			// could use Authority
			get { return _Domain; }
		}
		
		/// Initializing constructor
		/// @todo enquoting of localPart
		/// @todo encoding of international domain names
		public MailtoUri(string localPart, string domain)
			: base(String.Format("{0}:{1}@{2}",UriSchemeMailto,System.Uri.EscapeDataString(localPart),domain))
		{
			ParseMailtoScheme(OriginalString);
		}
		
		/// Conversion constructor from string
		public MailtoUri(string uriString) : base(uriString) {
			ParseMailtoScheme(OriginalString);
		}

		/// Conversion constructor from base
		/// @note The combining constructor can be used with an empty relative uri to get the result.
		public MailtoUri(System.Uri uri) : base(uri,(string)null) {
			ParseMailtoScheme(OriginalString);
		}
		
		/// Parse the string for decoding the tel URI scheme.
		/// @exception UriFormatException in case the scheme and string format does not comply
		/// @exception ArgumentOutOfRangeException in case any of the tel-properties is out of range
		private void ParseMailtoScheme(string uriString) {
			Match m = MailtoRegex.Match(uriString);
			if (!m.Success || (Scheme != UriSchemeMailto)) {
				Exception e = new UriFormatException("not a 'mailto:' URI");
				e.Data.Add("uri",uriString);
				throw e;
			}
			if (m.Groups["latom"].Success) {
				_LocalPart = UnescapeDataString(m.Groups["latom"].Value);
			}
			else if (m.Groups["qs"].Success) {
				_LocalPart = UnescapeDataString(m.Groups["qs"].Value);
			}
			_Domain = m.Groups["domain"].Value;
		}

		///
		/// Tries to convert the specified string to a mailto URI.
		/// First is tried to match a mailto-URI.
		/// Second is tried to match an Internet mail address.
		public static bool TryCreate(string value, out MailtoUri uri) {
			try {
				if (!String.IsNullOrEmpty(value)) {
					if (value.StartsWith("mailto:")) {
						uri = new MailtoUri(value);
						return true;
					}
					else {
						Match m = EmailAddressRegex.Match(value);
						uri = new MailtoUri(m.Groups["local"].Value,m.Groups["domain"].Value);
						return true;
					}
				}
			}
			catch (Exception) {
			}
			uri = null;
			return false;
		}

		public static bool TryCreate(out MailtoUri uri, string localPart, string domain) {
			try {
				uri = new MailtoUri(localPart,domain);
			}
			catch (Exception) {
				uri = null;
				return false;
			}
			return true;
		}
	}
	
	///
	/// An abstract base class of Uniform Resource Identifiers that may carry a single set of parameters.
	/// Examples of these are the TEL and GEO URIs.
	///
	/// A parameter consists of semi-colon delimiter, a parameter name, optionally followed by an equal
	/// sign and a parameter value.
	///
	/// @note GetHashCode() is overridden to implement a simpler algorithm than in the System.Uri class,
	///       usually sufficient for this class of URIs.
	///
	/// @see https://tools.ietf.org/html/rfc3986 (URI Generic Syntax, only references parameter usage)
	///
	public class ParameterizedUri : Uri {

		/// StringDictionary uses CaseInsensitive key compare
		private StringDictionary _Parameters;

		/// Any additional parameters present
		public bool HasParameters {
			get { return (_Parameters != null) && (_Parameters.Count > 0); }
		}
		
		/// Tests whether the other uri has exactly the same parameters.
		/// Parameter names are treated case-insensitive, but the values are compared case-sensitive,
		/// actually by ordinal.
		/// @param other the other URI
		/// @param exclude these parameters are compared separately.
		/// @param valueComparison the type of comparison of the values
		/// 
		public bool HasEqualParameters(ParameterizedUri other,
				string[] exclude, StringComparison valueComparison = StringComparison.OrdinalIgnoreCase) {
			// match additional parameters
			if (HasParameters ^ other.HasParameters) {
				return false;
			}
			if (HasParameters) {
				// match each individual parameter (with "binary" value compare)
				foreach (DictionaryEntry entry in Parameters) {
					if (!Array.Exists(exclude, s => s == (string)entry.Key)) {
						if (String.Compare((string)entry.Value,other.Parameters[(string)entry.Key],valueComparison) != 0) {
							return false;
						}
					}
				}
			}
			return true;
		}

		/// Additional parameters.
		public StringDictionary Parameters {
			get { return _Parameters; }
		}
		
		public ParameterizedUri(string uriString) : base(uriString) {
		}

		public ParameterizedUri(string uriString, UriKind uriKind) : base(uriString,uriKind) {
		}

		public ParameterizedUri(System.Uri baseUri, string relativeUri) : base(baseUri,relativeUri) {
		}

		public ParameterizedUri(System.Uri baseUri, System.Uri relativeUri) : base(baseUri,relativeUri) {
		}

		public override int GetHashCode() {
			// a simpler solution than using the Uri implementation
			return StringComparer.InvariantCultureIgnoreCase.GetHashCode(OriginalString);
			// return base.GetHashCode();
		}

		/// Get the value of the specified parameter.
		public string GetParameter(string name) {
			return _Parameters == null ? null : _Parameters[name];
		}

		/// Parse the regular expression-captured parameters from the URI to a dictionary of strings.
		/// The captures should not contain the semi-colon delimiter, only name and optionally equals sign and value.
		/// Parameter names SHOULD be lower case, so we lower them to be sure.
		/// @exception ArgumentException A parameter with the same key already exists.
		protected void ParseParameterCaptures(CaptureCollection captures) {
			if (captures != null && captures.Count > 0) {
				if (_Parameters == null) {
					_Parameters = new StringDictionary();
				}
				foreach (Capture c in captures) {
					// look for a value
					int eq = c.Value.IndexOf('=');
					if (eq < 0) {
						_Parameters.Add(c.Value.ToLower(), null);
					}
					else {
						_Parameters.Add(c.Value.Substring(0,eq).ToLower(), System.Uri.UnescapeDataString(c.Value.Substring(eq+1)));
					}
				}
			}
		}
	}

	///
	/// A Uniform Resource Identifier for Telephone Numbers.
	///
	/// A telephone number is an identifier for a termination point in the telephone network.
	/// The "tel"-scheme URI is specified in RFC3966.
	/// 
	/// ITU-T E.123 recommends the use of space characters as visual separators in printed telephone numbers,
	/// but a "tel" URI MUST NOT use spaces in visual separators to avoid excessive escaping. You can convert E.123 numbers
	/// with NormalizeNumber().
	///
	/// @see https://tools.ietf.org/html/rfc3966
	///
	public class TelUri : ParameterizedUri {
		public static readonly string UriSchemeTel = "tel";
		/// match global and local numbers and the optional parameters after the number
		/// @note You cannot capture the individual pname[=pvalue] pairs at once
		/// RFC3966 compliant reg-ex for a TelUri
		public static readonly Regex TelRegex = new Regex(@"^tel:((?<global>\+[0-9\-\.\(\)]*[0-9][0-9\-\.\(\)]*)|(?<local>[0-9A-F\*\#\-\.\(\)]*[0-9A-F\*\#][0-9A-F\*\#\-\.\(\)]*))(;(?<par>[^;]+))*",
			RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
		/// A regex for matching or replacing visual separators of a phone number.
		public static readonly Regex ReplaceVisualSeparatorsRegex = new Regex(@"[\-\.\(\)]",
			RegexOptions.Compiled|RegexOptions.CultureInvariant);
		public static readonly Regex GlobalNumberRegex = new Regex(@"^(?<global>\+[0-9\-\.\(\)]*[0-9][0-9\-\.\(\)]*)",
			RegexOptions.Compiled | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
		/// These parameters are specifically handled on compare
		public static readonly string[] ExcludeKnownParameters = { "phone-context" };
			
		/// Globally unique numbers are identified by the leading "+" character.
		/// Global numbers MUST be composed with the country (CC) and national (NSN) numbers as
		/// specified in E.123 [E.123] and E.164 [E.164].
		/// Globally unique numbers are unambiguous everywhere in the world and SHOULD be used.
		private bool _IsGlobal;
		/// The global-number-digits or local-number-digits of the phone number, with the visual separators removed.
		/// Includes global number prefix (if any) and visual separators.
		private string _Number;
		/// The normalized phone context descriptor of a local number.
		private string _Context;

		/// The global-number-digits or local-number-digits of the phone number, with any visual separators removed.
		public string Number {
			get { return _Number; }
		}

		/// Get the phone extension number
		public string Extension {
			get { return GetParameter("ext"); }
		}
		
		/// Checks if the Local Number Phone Context is a domain name (return value true) or a global number (return value false).
		/// If the phone number IsGlobal, false is returned also.
		public bool HasDomainNameContext {
			get { return !IsGlobal && !GlobalNumberRegex.Match(PhoneContext).Success; }
		}

		/// Is the number a global telephone number?
		/// Globally unique numbers are identified by the leading "+" character.
		/// Global numbers MUST be composed with the country (CC) and national (NSN) numbers as specified in E.123 and E.164.
		/// Globally unique numbers are unambiguous everywhere in the world.
		public bool IsGlobal {
			get { return _IsGlobal; }
		}

		///
		/// Get the normalized phone context of the local number. Use GetParameter("phone-context") to get
		/// the non-normalized phone context parameter.
		///
		/// Local numbers MUST have a 'phone-context' parameter that identifies the scope of their validity.
		/// The parameter MUST be chosen to identify the local context within which the number is unique unambiguously.
		/// Thus, the combination of the descriptor in the 'phone-context' parameter and local number is again globally unique.
		/// The parameter value is defined by the assignee of the local number. It does NOT indicate a prefix that turns
		/// the local number into a global (E.164) number.
		///
		public string PhoneContext {
			get {
				return _IsGlobal ? null : _Context;
			}
		}
		
		/// Get the ISDN aubaddress
		public string Subaddress {
			get { return GetParameter("isub"); }
		}

		/// Initializing constructor
		/// @note Local phone numbers need a PhoneContext descriptor.
		public TelUri(string number, string phoneContext = null)
			: base(String.Format("{0}:{1}{2}",UriSchemeTel,number,
				((phoneContext == null) ? null : String.Format(";phone-context={0}",phoneContext))
				))
		{
			ParseTelScheme(OriginalString);
		}
		
		/// Conversion constructor from string
		public TelUri(string uriString) : base(uriString) {
			ParseTelScheme(OriginalString);
		}

		/// Conversion constructor from base
		/// @note The combining constructor can be used with an empty relative uri to get the result.
		public TelUri(System.Uri uri) : base(uri,(string)null) {
			ParseTelScheme(OriginalString);
		}
		
		///
		/// Equals
		///
		/// Overrides default function (in Uri class)
		///
		/// @pre <comparand> is an object of class GeoUri, Uri, or String
		///
		/// @return true if objects have the same value, else false
		/// @exception none
		///
		public override bool Equals(object comparand) {
			if ((object)comparand == null) {
				return false;
			}
			if ((object)this == (object)comparand) {
				return true;
			}

			TelUri other = comparand as TelUri;

			//
			// we allow comparisons of Uri and String objects only. If a string
			// is passed, convert to TelUri. This is inefficient, but allows us to
			// canonicalize the comparand, making comparison possible
			//
			if ((object)other == null) {
				Uri u = comparand as Uri;
				string s = ((object)u != null) ? u.ToString() : (comparand as string);
				if ((object)s == null) {
					return false;
				}
				Match m = TelRegex.Match(s);
				if (!m.Success) {
					return false;
				}
				// the string or Uri -is- a tel uri: create one (but catch exceptions)
				try {
					other = new TelUri(s);
				}
				catch (Exception) {
					return false;
				}
			}
			// apply the RFC3966 comparison rules
			if (IsGlobal ^ other.IsGlobal) {
				return false;
			}
			if (String.Compare(Number,other.Number,StringComparison.OrdinalIgnoreCase) != 0) {
				return false;
			}
			if (!IsGlobal) {
				// compare the PhoneContext
				if (PhoneContext != other.PhoneContext) {
					return false;
				}
			}
			// match additional parameters
			if (!HasEqualParameters(other,ExcludeKnownParameters,StringComparison.OrdinalIgnoreCase)) {
				return false;
			}
			return true;
		}

		/// Override required because override of Equals
		public override int GetHashCode() {
			return base.GetHashCode();
		}
		
		///
		/// Convert an ITU-T E.123 telephone number, using SPACE characters as visual separators,
		/// to a "tel" URI format number, using a HYPHEN-MINUS as visual separator.
		///
		public static string NormalizeNumber(string number) {
			return number == null ? null : number.Replace(' ','-');
		}

		/// Parse the string for decoding the tel URI scheme.
		/// @exception UriFormatException in case the scheme and string format does not comply
		/// @exception ArgumentOutOfRangeException in case any of the tel-properties is out of range
		private void ParseTelScheme(string uriString) {
			Match m = TelRegex.Match(uriString);
			if (!m.Success || (Scheme != UriSchemeTel)) {
				Exception e = new UriFormatException("not a 'tel:' URI");
				e.Data.Add("uri",uriString);
				throw e;
			}
			if (m.Groups["global"].Success) {
				_IsGlobal = true;
				_Number = ReplaceVisualSeparatorsRegex.Replace(m.Groups["global"].Value,"");
			}
			else if (m.Groups["local"].Success) {
				_IsGlobal = false;
				_Number = ReplaceVisualSeparatorsRegex.Replace(m.Groups["local"].Value,"");
			}
			if (m.Groups["par"].Success) {
				ParseParameterCaptures(m.Groups["par"].Captures);
				// check that ext and isub do not appear both
				if (Extension != null && Subaddress != null) {
					Exception e = new UriFormatException("a phone extension number and an ISDN subaddress are mutually exclusive");
					e.Data.Add("uri",uriString);
					throw e;
				}
			}
			if (!IsGlobal) {
				_Context = GetParameter("phone-context");
				if (String.IsNullOrEmpty(_Context)) {
					Exception e = new UriFormatException("a local phone number requires a 'phone-context' parameter");
					e.Data.Add("uri",uriString);
					throw e;
				}
				if (GlobalNumberRegex.Match(_Context).Success) {
					// remove the visual separators
					_Context = ReplaceVisualSeparatorsRegex.Replace(_Context,"");
				}
				else {
					// _Context should be a domain name, normalize it to lower case for comparison
					_Context = _Context.ToLower();
				}
			}
		}

		///
		/// Tries to convert the specified string to a tel URI.
		/// - try a "tel" URI string
		/// - try a global telephone number
		public static bool TryCreate(string value, out TelUri uri) {
			try {
				if (!String.IsNullOrEmpty(value)) {
					if (value.StartsWith("tel:")) {
						uri = new TelUri(value);
						return true;
					}
					else {
						// try to match a (global) telephone number that we can convert into a telephone URI.
						// For local numbers, we need a phone-context to be specified; to complex for this code.
						// space is not allowed in a URI, but regularly used as visual separator: replace with allowed visual separator '-'
						string val = NormalizeNumber(value);
						if (GlobalNumberRegex.Match(val).Success) {
							uri = new TelUri(val,null);
							return true;
						}
					}
				}
			}
			catch (Exception) {
			}
			uri = null;
			return false;
		}

		public static bool TryCreate(out TelUri uri, string number, string phoneContext = null) {
			try {
				uri = new TelUri(number,phoneContext);
			}
			catch (Exception) {
				uri = null;
				return false;
			}
			return true;
		}
	}
	
	///
	/// A base class of Uniform Resource Identifiers that provides an object representation of a URI.
	///
	/// The main reason for this override of System.Uri is the behaviour of System.Uri.ToString(),
	/// which returns not a URI, but a (partly) unescaped display string.
	///
	/// @see https://tools.ietf.org/html/rfc3986 (URI Generic Syntax)
	///
	public class Uri : System.Uri {
		/// Match any percent-encoding with one or two lower case hex-digits 'a'..'f'.
		public static readonly Regex PercentHexNormalizeRegex = new Regex(@"%([a-z][0-9A-Za-z]|[0-9A-Fa-z][a-z])",
			RegexOptions.Compiled | RegexOptions.CultureInvariant);
		/// A regex for matching or replacing series of one or more white space characters.
		public static readonly Regex WhiteSpacesRegex = new Regex(@"\s+",
			RegexOptions.Compiled | RegexOptions.CultureInvariant);

		public Uri(string uriString) : base(uriString) {
		}

		public Uri(string uriString, UriKind uriKind) : base(uriString,uriKind) {
		}

		public Uri(System.Uri baseUri, string relativeUri) : base(baseUri,relativeUri) {
		}

		public Uri(System.Uri baseUri, System.Uri relativeUri) : base(baseUri,relativeUri) {
		}
/*
		///  A static short-cut to Uri.Equals
		public static bool operator == (Uri uri1, Uri uri2) {
			if ((object)uri1 == (object)uri2) {
				return true;
			}
			if ((object)uri1 == null || (object)uri2 == null) {
				return false;
			}
			return uri2.Equals(uri1);
		}

		///  A static short-cut to !Uri.Equals
		public static bool operator != (Uri uri1, Uri uri2) {
			if ((object)uri1 == (object)uri2) {
				return false;
			}
			if ((object)uri1 == null || (object)uri2 == null) {
				return true;
			}
			return !uri2.Equals(uri1);
		}
*/
		///
		/// Normalize a percent-encoded string: convert any lower-case 
		/// hexadecimal digits 'a'..'f' to 'A'..'F'.
		///
		/// @see https://tools.ietf.org/html/rfc3986#section-2.1
		///
		public static string NormalizePercentEncoding(string encodedString) {
			if (!String.IsNullOrEmpty(encodedString)) {
				return PercentHexNormalizeRegex.Replace(encodedString,delegate(Match m){
					string lower = m.ToString();
					char[] upper = {
						lower[0],
						(char.IsLower(lower[1]) ? char.ToUpper(lower[1]) : lower[1]),
						(char.IsLower(lower[2]) ? char.ToUpper(lower[2]) : lower[2])
					};
					return new string(upper);
				});
			}
			return encodedString;
		}

		public override string ToString() {
			// @todo OriginalString might be replaced with GetComponents() ?
			return IsAbsoluteUri ? AbsoluteUri : OriginalString;
		}

		///
		/// Tries to convert the specified URI string to a URI
		public static bool TryCreate(string uriString, out Uri uri) {
			try {
				uri = new Uri(uriString);
			}
			catch (Exception) {
				uri = null;
				return false;
			}
			return true;
		}

		///
		/// Tries to convert the specified URI string to a URI
		public static bool TryCreate(string uriString, UriKind uriKind, out Uri uri) {
			try {
				uri = new Uri(uriString,uriKind);
			}
			catch (Exception) {
				uri = null;
				return false;
			}
			return true;
		}
	}

	///
	/// A Uniform Resource Identifier for Uniform Resource Names.
	///
	/// A Uniform Resource Name (URN) is a Uniform Resource Identifier (URI)
	/// that is assigned under the "urn" URI scheme and a particular URN
	/// namespace, with the intent that the URN will be a persistent,
	/// location-independent resource identifier.
	/// The "urn"-scheme URI is specified in RFC8141.
	///
	/// @todo support r-, q-, and f-components
	/// 
	/// @see https://tools.ietf.org/html/rfc8141 (Uniform Resource Names)
	/// @see https://tools.ietf.org/html/rfc2141 (URN Syntax, obsolete)
	/// @see https://tools.ietf.org/html/rfc3986 (URI Generic Syntax)
	///
	public class UrnUri : Uri {
		public static readonly string UriSchemeUrn = "urn";
		public static readonly string UuidNamespace = "uuid";
		public static readonly string PublicIdNamespace = "publicid";

		/// Match the URI components of a URN
		/// @see https://www.ietf.org/rfc/rfc2141.txt (obsolete)
		/// @see https://tools.ietf.org/html/rfc8141
		public static Regex UrnRegex = new Regex(@"^(?i:urn:)(?<nid>[A-Za-z0-9][A-Za-z0-9\-]{0,30}[A-Za-z0-9]):(?<nss>[^\?#]+)(?<rq>\?[^#]+)?(?<f>#.*)?",
			RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
		/// Match the URI components of a UUID URN (@todo rqf)
		public static Regex UuidUrnRegex = new Regex(@"^(?i:urn:)(?i:uuid:)(?<uuid>.+)",
			RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
		/// Match the URI components of a PublicIdentifier URN (@todo rqf)
		public static Regex PublicIdUrnRegex = new Regex(@"^(?i:urn:)(?i:publicid:)(?<publicid>.+)",
			RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
		/// XML PubidChar ::= #x20 | #xD | #xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%]
		/// @note We included HT as valid PubidChar, since during normalization HT is converted to SP,
		///		just like CR and LF, so it is odd not to allow HT
		public static Regex PublicIdentifierRegex = new Regex(@"[\t\r\n\x20!#$%'-;=\?-Z_a-z]+",
			RegexOptions.Compiled | RegexOptions.CultureInvariant);

		/// The Namespace Identifier.
		private string _NID;
		/// The Namespace Specific String.
		private string _NSS;

		/// The normalized Namespace Identifier.
		public string NID {
			get { return _NID; }
		}

		/// The normalized Namespace Specific String.
		public string NSS {
			get { return _NSS; }
		}

		/// Initializing constructor
		/// @param nid the Namespace Identifier
		/// @param nss the Namespace Specific String
		public UrnUri(string nid, string nss)
			: base(String.Format("{0}:{1}:{2}",UriSchemeUrn,nid,nss))
		{
			ParseUrnScheme(OriginalString);
		}
		
		/// Conversion constructor from string
		public UrnUri(string uriString) : base(uriString) {
			ParseUrnScheme(OriginalString);
		}

		/// Conversion constructor from base
		/// @note The combining constructor can be used with an empty relative uri to get the result.
		public UrnUri(System.Uri uri) : base(uri,(string)null) {
			ParseUrnScheme(OriginalString);
		}
		
		///
		/// Equals
		///
		/// Overrides default function (in Uri class) to determine URN-equivalence
		/// according to RFC8141.
		///
		/// @pre <comparand> is an object of class UrnUri, Uri, or String
		///
		/// @return true if objects have the same value, else false
		/// @exception none
		///
		public override bool Equals(object comparand) {
			if ((object)comparand == null) {
				return false;
			}
			if ((object)this == (object)comparand) {
				return true;
			}

			UrnUri other = comparand as UrnUri;

			//
			// we allow comparisons of Uri and String objects only. If a string
			// is passed, convert to UrnUri. This is inefficient, but allows us to
			// canonicalize the comparand, making comparison possible
			//
			if ((object)other == null) {
				Uri u = comparand as Uri;
				string s = ((object)u != null) ? u.ToString() : (comparand as string);
				if ((object)s == null) {
					return false;
				}
				// try to create an UrnUri from the string or Uri (catch exceptions)
				try {
					other = new UrnUri(s);
				}
				catch (Exception) {
					return false;
				}
			}
			// apply the RFC8141 comparison rules
			if (String.Compare(NID,other.NID,StringComparison.Ordinal) != 0) {
				return false;
			}
			if (String.Compare(NSS,other.NSS,StringComparison.Ordinal) != 0) {
				return false;
			}
			return true;
		}

		/// Override required because override of Equals
		public override int GetHashCode() {
			return base.GetHashCode();
		}

		/// Get the public identifier.
		/// Returns null if the Identifier is not a public identifier.
		public string PublicIdentifier {
			get {
				if (NID == PublicIdNamespace) {
					return UntranscribePublicIdentifier(NSS);
				}
				return null;
			}
		}
	
		/// Get the universally unique identifier.
		/// Returns null if the Identifier is not a UUID.
		public Guid? UUID {
			get {
				if (NID == UuidNamespace) {
					return new System.Guid(NSS);
				}
				return null;
			}
		}

		/// Normalize a public identifier as specified in RFC3151 (or as for xml:id):
		/// compress white space to a single space and trim leading and trailing white space.
		/// @see https://www.w3.org/TR/xml-id/#id-avn
		public static string NormalizePublicIdentifier(string value) {
			return WhiteSpacesRegex.Replace(value," ").Trim();
		}

		/// Transcribe a public identifier as specified in RFC3151:
		/// encode a public identifier for storage in a URI.
		/// @pre the identifier is normalized
		/// @see https://www.ietf.org/rfc/rfc3151.txt
		public static string TranscribePublicIdentifier(string value) {
			StringBuilder sb = new StringBuilder(value.Length);
			for (int i = 0; i < value.Length; i++) {
				switch (value[i]) {
				case ' ': sb.Append('+'); break;
				case '+': sb.Append("%2B"); break;
				case '/':
					if (((i+1) < value.Length) && (value[i+1] == '/')) {
						sb.Append(':');
						i++;
					}
					else {
						sb.Append("%2F");
					}
					break;
				case ':':
					if (((i+1) < value.Length) && (value[i+1] == ':')) {
						sb.Append(';');
						i++;
					}
					else {
						sb.Append("%3A");
					}
					break;
				case ';': sb.Append("%3B"); break;
				case '\x27': sb.Append("%27"); break;
				case '?': sb.Append("%3F"); break;
				case '#': sb.Append("%23"); break;
				case '%': sb.Append("%25"); break;
				default: sb.Append(value[i]); break;
				}
			}
			return sb.ToString();
		}

		/// Decode the URI-representation of a public identifier as 
		/// specified in RFC3151 back into a public identifier.
		/// @see https://www.ietf.org/rfc/rfc3151.txt
		public static string UntranscribePublicIdentifier(string value) {
			StringBuilder sb = new StringBuilder(value);
			sb.Replace(":","//");
			sb.Replace(";","::");
			sb.Replace('+',' ');
			return System.Uri.UnescapeDataString(sb.ToString());
		}
		
		/// Create a new Universally Unique Identifier (UUID) URI for the specified uuid. 
		/// If no uuid is specified, a new one in generated.
		public static UrnUri NewUuidUrnUri(System.Guid? uuid = null) {
			if (uuid == null) {
				uuid = System.Guid.NewGuid();
			}
			return new UrnUri(UuidNamespace,uuid.ToString());
		}

		/// Parse the string for decoding the urn URI scheme.
		/// @exception UriFormatException in case the scheme and string format does not comply
		/// @exception ArgumentOutOfRangeException in case any of the urn-properties is out of range
		private void ParseUrnScheme(string uriString) {
			Match m = UrnRegex.Match(uriString);
			if (!m.Success || (Scheme != UriSchemeUrn)) {
				Exception e = new UriFormatException("not a 'urn:' URI");
				e.Data.Add("uri",uriString);
				throw e;
			}
			if (m.Groups["nid"].Success) {
				// normalize to lower case for URN equivalence
				_NID = m.Groups["nid"].Value.ToLower();
			}
			if (m.Groups["nss"].Success) {
				// normalize any percent-encoded characters in the NSS (that is, all character
				// triplets that match the <pct-encoding> production found in
				// Section 2.1 of the base URI specification [RFC3986]), by
				// conversion to upper case for the digits A-F.
				_NSS = NormalizePercentEncoding(m.Groups["nss"].Value);
			}
			// @todo rq and f parsing
		}

		///
		/// Tries to convert the specified string to a urn URI.
		/// - try a "urn" URI string
		/// - try a GUID string to create a "urn:uuid" URI
		/// - try a Public Identifier string to create a "urn:publicid" URI
		public static bool TryCreate(string value, out UrnUri uri) {
			try {
				if (!String.IsNullOrEmpty(value)) {
					if (value.StartsWith("urn:")) {
						uri = new UrnUri(value);
						return true;
					}
					else {
						// try to match a UUID
						Guid uuid;
						if (System.Guid.TryParse((string)value,out uuid)) {
							uri = NewUuidUrnUri(uuid);
							return true;
						}
						else {
							// let us try matching a (Formal) Public Identifier
							// @note most URIs like a data-URI also qualify as PublicIdentfier!
							// if we don't want those encoded as UrnUri, we need to recognize a URI first!!
							string id = NormalizePublicIdentifier((string)value);
							if (PublicIdentifierRegex.Match(id).Success) {
								id = TranscribePublicIdentifier(id);
								uri = new UrnUri(PublicIdNamespace, id );
								return true;
							}
						}
					}
				}
			}
			catch (Exception) {
			}
			uri = null;
			return false;
		}

		public static bool TryCreate(out UrnUri uri, string nid, string nss) {
			try {
				uri = new UrnUri(nid,nss);
			}
			catch (Exception) {
				uri = null;
				return false;
			}
			return true;
		}
	}
}
