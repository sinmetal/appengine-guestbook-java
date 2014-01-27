/**
 * Copyright 2012 Google Inc. All Rights Reserved. 
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.appengine.demos.guestbook;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.FetchOptions;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;
import com.google.appengine.api.datastore.Query;
import com.google.appengine.api.memcache.MemcacheService;
import com.google.appengine.api.memcache.MemcacheServiceFactory;
import com.google.appengine.api.users.User;
import com.google.appengine.api.users.UserService;
import com.google.appengine.api.users.UserServiceFactory;

public class SignGuestbookServlet extends HttpServlet {
	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws IOException {
		UserService userService = UserServiceFactory.getUserService();
		User user = userService.getCurrentUser();

		String guestbookName = req.getParameter("guestbookName");
		Key guestbookKey = KeyFactory.createKey("Guestbook", guestbookName);
		String content = req.getParameter("content");
		Date date = new Date();
		Entity greeting = new Entity("Greeting", guestbookKey);
		greeting.setProperty("user", user);
		greeting.setProperty("date", date);
		greeting.setProperty("content", content);

		DatastoreService datastore = DatastoreServiceFactory
				.getDatastoreService();
		datastore.put(greeting);
		MemcacheService memcacheService = MemcacheServiceFactory
				.getMemcacheService();
		memcacheService.put(guestbookKey, greeting);

		resp.sendRedirect("/guestbook.jsp?guestbookName=" + guestbookName);

//		Query query = new Query("Greeting", guestbookKey).setKeysOnly()
//				.addSort("date", Query.SortDirection.DESCENDING);
//		List<Entity> greetingsForKeyOnly = datastore.prepare(query).asList(
//				FetchOptions.Builder.withLimit(5));
//		datastore.prepare(query);
//
//		List<Key> keys = new ArrayList<>();
//		for (Entity entity : greetingsForKeyOnly) {
//			keys.add(entity.getKey());
//		}
//		Map<Key, Object> memcacheAll = memcacheService.getAll(keys);
//		for (Entry<Key, Object> obj : memcacheAll.entrySet()) {
//			Entity entity = (Entity) obj.getValue();
//			System.out.println(entity.getProperty("content"));
//		}
//		List<Key> lackKeys = new ArrayList<>();
//		for (Key key : keys) {
//			if (memcacheAll.containsKey(key) == false) {
//				lackKeys.add(key);
//			}
//		}
//		Map<Key, Entity> datastoreAll = datastore.get(lackKeys);
//		memcacheService.putAll(datastoreAll);
//
//		List<Entity> results = new ArrayList<>();
//		for (Key key : keys) {
//			if (memcacheAll.containsKey(key)) {
//				results.add((Entity) memcacheAll.get(key));
//			} else if (datastoreAll.containsKey(key)) {
//				results.add(datastoreAll.get(key));
//			}
//		}
//		System.out.println("memcache size = " + memcacheAll.size());
//		System.out.println("datastore size = " + datastoreAll.size());
//		System.out.println("all size = " + results.size());
	}
}
