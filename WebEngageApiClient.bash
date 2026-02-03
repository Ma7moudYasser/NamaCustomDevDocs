package com.namasoft.modules.supplychain.domain.utils.webengage;

import com.namasoft.common.utilities.*;
import com.namasoft.httpcommon.DefaultHttpClient;
import com.namasoft.infra.domainbase.util.DomainNamaJSON;

import java.io.IOException;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;


public class WebEngageApiClient
{
	private final String baseUrl;
	private final String licenseCode;
	private final String apiKey;

	private static final DateTimeFormatter ISO_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssZ");
	public WebEngageApiClient(WebEngageRegion region, String licenseCode, String apiKey)
	{
		this.baseUrl = region.getBaseUrl();
		this.licenseCode = licenseCode;
		this.apiKey = apiKey;
	}
	public WebEngageResponse trackUser(WebEngageUser user)
	{
		String url = buildUrl("users");
		Map<String, Object> body = user.toMap();
		return sendRequest(url, body);
	}
	public WebEngageResponse trackEvent(WebEngageEvent event)
	{
		String url = buildUrl("events");
		Map<String, Object> body = event.toMap();
		return sendRequest(url, body);
	}

	private String buildUrl(String resource)
	{
		return baseUrl + "v1/accounts/" + licenseCode + "/" + resource;
	}

	private Map<String, String> buildHeaders()
	{
		Map<String, String> headers = new HashMap<>();
		headers.put("Authorization", "Bearer " + apiKey);
		headers.put("Content-Type", "application/json");
		return headers;
	}

	private WebEngageResponse sendRequest(String url, Map<String, Object> body)
	{
		try (DefaultHttpClient client = new DefaultHttpClient())
		{
			com.namasoft.common.utilities.NaMaLogger.info("WebEngage API Request to: {0}", url);
			NaMaLogger.info("WebEngage API Request body: {0}", DomainNamaJSON.toJSONString(body));

			Map<String, Object> response = client.postObjectAndReturnMapResponse(
				url,
				buildHeaders(),
				new HashMap<>(),
				body
			);

			NaMaLogger.info("WebEngage API Response: {0}", DomainNamaJSON.toJSONString(response));

			return WebEngageResponse.fromMap(response);
		}
		catch (IOException e)
		{
			NaMaLogger.error("WebEngage API Error: {0}", e.getMessage());
			return WebEngageResponse.error(e.getMessage());
		}
	}


	public static String formatDateTime(ZonedDateTime dateTime)
	{
		if (dateTime == null)
			return null;
		return dateTime.format(ISO_FORMAT);
	}


	public enum WebEngageRegion
	{
		GLOBAL("https://api.webengage.com/"),
		INDIA("https://api.in.webengage.com/"),
		SAUDI_ARABIA("https://api.ksa.webengage.com/");

		private final String baseUrl;

		WebEngageRegion(String baseUrl)
		{
			this.baseUrl = baseUrl;
		}

		public String getBaseUrl()
		{
			return baseUrl;
		}
	}


	public static class WebEngageUser
	{
		private String userId;
		private String anonymousId;
		private String firstName;
		private String lastName;
		private String email;
		private String phone;
		private String gender;
		private String birthDate;
		private String company;
		private Boolean emailOptIn;
		private Boolean smsOptIn;
		private Boolean whatsappOptIn;
		private Map<String, Object> attributes = new HashMap<>();

		public WebEngageUser userId(String userId)
		{
			this.userId = userId;
			return this;
		}

		public WebEngageUser anonymousId(String anonymousId)
		{
			this.anonymousId = anonymousId;
			return this;
		}

		public WebEngageUser firstName(String firstName)
		{
			this.firstName = firstName;
			return this;
		}

		public WebEngageUser lastName(String lastName)
		{
			this.lastName = lastName;
			return this;
		}

		public WebEngageUser email(String email)
		{
			this.email = email;
			return this;
		}

		public WebEngageUser phone(String phone)
		{
			this.phone = phone;
			return this;
		}

		public WebEngageUser gender(String gender)
		{
			this.gender = gender;
			return this;
		}

		public WebEngageUser birthDate(String birthDate)
		{
			this.birthDate = birthDate;
			return this;
		}

		public WebEngageUser company(String company)
		{
			this.company = company;
			return this;
		}

		public WebEngageUser emailOptIn(Boolean emailOptIn)
		{
			this.emailOptIn = emailOptIn;
			return this;
		}

		public WebEngageUser smsOptIn(Boolean smsOptIn)
		{
			this.smsOptIn = smsOptIn;
			return this;
		}

		public WebEngageUser whatsappOptIn(Boolean whatsappOptIn)
		{
			this.whatsappOptIn = whatsappOptIn;
			return this;
		}

		public WebEngageUser attribute(String key, Object value)
		{
			if (ObjectChecker.isNotEmptyOrNull(value))
				this.attributes.put(key, value);
			return this;
		}

		public Map<String, Object> toMap()
		{
			Map<String, Object> map = new HashMap<>();
			if (ObjectChecker.isNotEmptyOrNull(userId))
				map.put("userId", userId);
			if (ObjectChecker.isNotEmptyOrNull(anonymousId))
				map.put("anonymousId", anonymousId);
			if (ObjectChecker.isNotEmptyOrNull(firstName))
				map.put("firstName", firstName);
			if (ObjectChecker.isNotEmptyOrNull(lastName))
				map.put("lastName", lastName);
			if (ObjectChecker.isNotEmptyOrNull(email))
				map.put("email", email);
			if (ObjectChecker.isNotEmptyOrNull(phone))
				map.put("phone", phone);
			if (ObjectChecker.isNotEmptyOrNull(gender))
				map.put("gender", gender);
			if (ObjectChecker.isNotEmptyOrNull(birthDate))
				map.put("birthDate", birthDate);
			if (ObjectChecker.isNotEmptyOrNull(company))
				map.put("company", company);
			if (emailOptIn != null)
				map.put("emailOptIn", emailOptIn);
			if (smsOptIn != null)
				map.put("smsOptIn", smsOptIn);
			if (whatsappOptIn != null)
				map.put("whatsappOptIn", whatsappOptIn);
			if (!attributes.isEmpty())
				map.put("attributes", attributes);
			return map;
		}
	}

	public static class WebEngageEvent
	{
		private String userId;
		private String anonymousId;
		private String eventName;
		private String eventTime;
		private Map<String, Object> eventData = new HashMap<>();

		public WebEngageEvent userId(String userId)
		{
			this.userId = userId;
			return this;
		}

		public WebEngageEvent anonymousId(String anonymousId)
		{
			this.anonymousId = anonymousId;
			return this;
		}

		public WebEngageEvent eventName(String eventName)
		{
			this.eventName = eventName;
			return this;
		}

		public WebEngageEvent eventTime(String eventTime)
		{
			this.eventTime = eventTime;
			return this;
		}

		public WebEngageEvent eventData(String key, Object value)
		{
			if (ObjectChecker.isNotEmptyOrNull(value))
				this.eventData.put(key, value);
			return this;
		}

		public Map<String, Object> toMap()
		{
			Map<String, Object> map = new HashMap<>();
			if (ObjectChecker.isNotEmptyOrNull(userId))
				map.put("userId", userId);
			if (ObjectChecker.isNotEmptyOrNull(anonymousId))
				map.put("anonymousId", anonymousId);
			map.put("eventName", eventName);
			if (ObjectChecker.isNotEmptyOrNull(eventTime))
				map.put("eventTime", eventTime);
			if (!eventData.isEmpty())
				map.put("eventData", eventData);
			return map;
		}
	}


	public static class WebEngageResponse
	{
		private boolean success;
		private String status;
		private String errorMessage;

		public boolean isSuccess()
		{
			return success;
		}

		public String getStatus()
		{
			return status;
		}

		public String getErrorMessage()
		{
			return errorMessage;
		}

		@SuppressWarnings("unchecked")
		public static WebEngageResponse fromMap(Map<String, Object> map)
		{
			WebEngageResponse response = new WebEngageResponse();
			if (map != null && map.containsKey("response"))
			{
				Map<String, Object> responseData = (Map<String, Object>) map.get("response");
				response.status = ObjectChecker.toStringOrEmpty(responseData.get("status"));
				response.success = "queued".equalsIgnoreCase(response.status);
			}
			else
			{
				response.success = false;
				response.errorMessage = "Invalid response from WebEngage API";
			}
			return response;
		}

		public static WebEngageResponse error(String message)
		{
			WebEngageResponse response = new WebEngageResponse();
			response.success = false;
			response.errorMessage = message;
			return response;
		}
	}
}
