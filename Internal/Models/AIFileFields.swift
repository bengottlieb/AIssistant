//
//  AIFileFields.swift
//  Internal
//
//  Created by Ben Gottlieb on 3/1/26.
//

import SyncEngine

public enum AIFileFields {
	public static let content = CKRecordField<String>.string("content")
	public static let fileName = CKRecordField<String>.string("fileName")
	public static let platform = CKRecordField<String>.string("platform")
	public static let category = CKRecordField<String>.string("category")
	public static let relativePath = CKRecordField<String>.string("relativePath")
	/// JSON-encoded [BundleFile] for folder-based items (skills/plugins); nil
	/// for single-file records.
	public static let bundleData = CKRecordField<Data>.data("bundleData")
}
