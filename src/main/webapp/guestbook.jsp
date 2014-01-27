<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreService" %>
<%@ page import="com.google.appengine.api.datastore.DatastoreServiceFactory" %>
<%@ page import="com.google.appengine.api.datastore.Entity" %>
<%@ page import="com.google.appengine.api.datastore.FetchOptions" %>
<%@ page import="com.google.appengine.api.datastore.Key" %>
<%@ page import="com.google.appengine.api.datastore.KeyFactory" %>
<%@ page import="com.google.appengine.api.datastore.Query" %>
<%@ page import="com.google.appengine.api.memcache.MemcacheService" %>
<%@ page import="com.google.appengine.api.memcache.MemcacheServiceFactory" %>
<%@ page import="com.google.appengine.api.users.User" %>
<%@ page import="com.google.appengine.api.users.UserService" %>
<%@ page import="com.google.appengine.api.users.UserServiceFactory" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Map.Entry" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<html>
<head>
    <link type="text/css" rel="stylesheet" href="/stylesheets/main.css"/>
</head>

<body>

<%
    String guestbookName = request.getParameter("guestbookName");
    if (guestbookName == null) {
        guestbookName = "default";
    }
    pageContext.setAttribute("guestbookName", guestbookName);
    UserService userService = UserServiceFactory.getUserService();
    User user = userService.getCurrentUser();
    if (user != null) {
        pageContext.setAttribute("user", user);
%>
<p>Hello, ${fn:escapeXml(user.nickname)}! (You can
    <a href="<%= userService.createLogoutURL(request.getRequestURI()) %>">sign out</a>.)</p>
<%
} else {
%>
<p>Hello!
    <a href="<%= userService.createLoginURL(request.getRequestURI()) %>">Sign in</a>
    to include your name with greetings you post.</p>
<%
    }
%>

<%
    DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
	MemcacheService memcacheService = MemcacheServiceFactory.getMemcacheService();
    Key guestbookKey = KeyFactory.createKey("Guestbook", guestbookName);
//    // Run an ancestor query to ensure we see the most up-to-date
//    // view of the Greetings belonging to the selected Guestbook.
	Query query = new Query("Greeting", guestbookKey).setKeysOnly().addSort("date", Query.SortDirection.DESCENDING);
	List<Entity> greetingsForKeyOnly = datastore.prepare(query).asList(FetchOptions.Builder.withLimit(5));
	datastore.prepare(query);
	
	List<Key> keys = new ArrayList<Key>();
	for (Entity entity : greetingsForKeyOnly) {
		keys.add(entity.getKey());
	}
	Map<Key, Object> memcacheAll = memcacheService.getAll(keys);
	for (Entry<Key, Object> obj : memcacheAll.entrySet()) {
		Entity entity = (Entity) obj.getValue();
		System.out.println(entity.getProperty("content"));
	}
	List<Key> lackKeys = new ArrayList<Key>();
	for (Key key : keys) {
		if (memcacheAll.containsKey(key) == false) {
			lackKeys.add(key);
		}
	}
	Map<Key, Entity> datastoreAll = datastore.get(lackKeys);
	memcacheService.putAll(datastoreAll);
	
	List<Entity> greetings = new ArrayList<Entity>();
	for (Key key : keys) {
		if (memcacheAll.containsKey(key)) {
			greetings.add((Entity) memcacheAll.get(key));
		} else if (datastoreAll.containsKey(key)) {
			greetings.add(datastoreAll.get(key));
		}
	}
	System.out.println("memcache size = " + memcacheAll.size());
	System.out.println("datastore size = " + datastoreAll.size());
	System.out.println("all size = " + greetings.size());

    if (greetings.isEmpty()) {
%>
<p>Guestbook '${fn:escapeXml(guestbookName)}' has no messages.</p>
<%
} else {
%>
<p>Messages in Guestbook '${fn:escapeXml(guestbookName)}'.</p>
<%
    for (Entity greeting : greetings) {
        pageContext.setAttribute("greeting_content",
                greeting.getProperty("content"));
        if (greeting.getProperty("user") == null) {
%>
<p>An anonymous person wrote:</p>
<%
} else {
    pageContext.setAttribute("greeting_user",
            greeting.getProperty("user"));
%>
<p><b>${fn:escapeXml(greeting_user.nickname)}</b> wrote:</p>
<%
    }
%>
<blockquote>${fn:escapeXml(greeting_content)}</blockquote>
<%
        }
    }
%>

<form action="/sign" method="post">
    <div><textarea name="content" rows="3" cols="60"></textarea></div>
    <div><input type="submit" value="Post Greeting"/></div>
    <input type="hidden" name="guestbookName" value="${fn:escapeXml(guestbookName)}"/>
</form>

<form action="/guestbook.jsp" method="get">
    <div><input type="text" name="guestbookName" value="${fn:escapeXml(guestbookName)}"/></div>
    <div><input type="submit" value="Switch Guestbook"/></div>
</form>

</body>
</html>
