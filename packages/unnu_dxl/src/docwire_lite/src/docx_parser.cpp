/*********************************************************************************************************************************************/
/*  DocWire SDK: Award-winning modern data processing in C++20. SourceForge Community Choice & Microsoft support. AI-driven processing.      */
/*  Supports nearly 100 data formats, including email boxes and OCR. Boost efficiency in text extraction, web data extraction, data mining,  */
/*  document analysis. Offline processing possible for security and confidentiality                                                          */
/*                                                                                                                                           */
/*  Copyright (c) SILVERCODERS Ltd, http://silvercoders.com                                                                                  */
/*  Project homepage: https://github.com/docwire/docwire                                                                                     */
/*                                                                                                                                           */
/*  SPDX-License-Identifier: GPL-2.0-only OR LicenseRef-DocWire-Commercial                                                                   */
/*********************************************************************************************************************************************/





#include <algorithm>
#include <codecvt>
#include <mutex>
#include <new>
#include <map>
#include <set>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include "data_stream.h"
#include "error_tags.h"
#include "log.h"
#include "make_error.hpp"
#include "misc.h"
#include "throw_if.hpp"

#include <duckx.hpp>

#include "docx_parser.h"

namespace docwire
{

	namespace
	{
		std::mutex load_document_mutex;
	} // unnamed namespace

	static void appendToString(void* stream, const char* text, int size) {
		if (stream) {
			auto val = (std::ostringstream*)stream;
			if (strlen(text) > 0) {
				*val << text;
			}
		}
	}

	typedef std::unique_ptr<duckx::Document> duckx_document_ptr;

	template<>
	struct pimpl_impl<DocxParser> : with_pimpl_owner<DocxParser>
	{
		pimpl_impl(DocxParser& owner) : with_pimpl_owner{ owner } {}
		duckx_document_ptr doc;

	};

	void DocxParser::loadDocument(const data_source& data)
	{
		docwire_log_func();
		std::lock_guard<std::mutex> load_document_mutex_lock(load_document_mutex);
		std::optional<std::filesystem::path> path = data.path();
		if (data.path().has_value()) {
			try {
				auto path = std::string(data.path().value().string().c_str());
				auto document = new duckx::Document(path);
				impl().doc = duckx_document_ptr(document);
				impl().doc->open();
			}
			catch (std::exception& ex) {
				std::throw_with_nested(make_error("Unable to open document"));
			}
		}
	}

	DocxParser::DocxParser() {}

	std::mutex docx_mutex;


	DocxParser::~DocxParser() {
		destroy_impl();
	}


	void DocxParser::parse(const data_source& data)
	{
		docwire_log(debug) << "Using Docx parser.";
		{
			std::lock_guard<std::mutex> xpdf_mutex_lock(docx_mutex);
			renew_impl();
		}
		loadDocument(data);
		sendTag(tag::Document{});
		{
			std::lock_guard<std::mutex> xpdf_mutex_lock(docx_mutex);
			parseText();
			parseTables();
		}
		sendTag(tag::CloseDocument{});
	}



	void DocxParser::parseText()
	{
		docwire_log_func();
		int para_num = 0;
		for (auto p = impl().doc->paragraphs(); p.has_next(); p.next()) {
			std::string single_paragraph_text;
			para_num++;
			docwire_log_var(para_num);
			auto response = sendTag(tag::Paragraph{});
			if (response.skip)
			{
				continue;
			}
			if (response.cancel)
			{
				break;
			}
			try {
				for (auto r = p.runs(); r.has_next(); r.next()) {
					single_paragraph_text.append(r.get_text());
				}
				auto response = sendTag(tag::Text{ single_paragraph_text });
				if (response.cancel)
				{
					break;
				}
				auto response2 = sendTag(tag::CloseParagraph{});
				if (response2.cancel)
				{
					break;
				}
			}
			catch (const std::exception& e)
			{
				std::throw_with_nested(make_error(para_num));
			}
			docwire_log(debug) << "Paragraph processed" << docwire_log_streamable_var(para_num);

		}
	}

	void DocxParser::parseTables()
	{
		docwire_log_func();
		int tbl_num = 0;
		std::string prefix;
		for (auto p = impl().doc->tables(); p.has_next(); p.next()) {
			std::string single_paragraph_text;
			tbl_num++;
			auto tbl_string = std::to_string(tbl_num);
			prefix = tbl_string;
			docwire_log_var(tbl_string);
			auto table_response = sendTag(tag::Table{});
			if (table_response.skip)
			{
				continue;
			}
			if (table_response.cancel)
			{
				break;
			}
			try {
				int row_num = 0;
				for (auto r = p.rows(); r.has_next(); r.next()) {
					row_num++;
					auto row_string = std::to_string(row_num);
					prefix = tbl_string + "." + row_string;
					docwire_log_var(prefix);
					auto row_response = sendTag(tag::TableRow{});
					if (row_response.skip)
					{
						continue;
					}
					if (row_response.cancel)
					{
						break;
					}
					int cell_num = 0;
					for (auto c = r.cells(); c.has_next(); c.next()) {
						cell_num++;
						auto cell_string = std::to_string(cell_num);
						prefix = tbl_string + "." + row_string + "." + cell_string;
						docwire_log_var(prefix);
						auto cell_response = sendTag(tag::TableCell{});
						if (cell_response.skip)
						{
							continue;
						}
						if (cell_response.cancel)
						{
							break;
						}
						int para_num = 0;
						for (auto p = impl().doc->paragraphs(); p.has_next(); p.next()) {
							para_num++;
							auto para_string = std::to_string(para_num);
							docwire_log_var(prefix+" ("+ para_string+")");
							std::string single_paragraph_text;
							auto para_response = sendTag(tag::Paragraph{});
							if (para_response.skip)
							{
								continue;
							}
							if (para_response.cancel)
							{
								break;
							}
							for (auto r = p.runs(); r.has_next(); r.next()) {
								single_paragraph_text.append(r.get_text());
							}
							auto text_response = sendTag(tag::Text{ single_paragraph_text });
							if (text_response.cancel)
							{
								break;
							}
							auto response2 = sendTag(tag::CloseParagraph{});
							if (response2.cancel)
							{
								break;
							}
						}
						auto cc_response = sendTag(tag::CloseTableCell{});
						if (cc_response.cancel)
						{
							break;
						}

					}
					auto tr_response = sendTag(tag::CloseTableRow{});
					if (tr_response.cancel)
					{
						break;
					}
				}
				auto tbl_response2 = sendTag(tag::CloseTable{});
				if (tbl_response2.cancel)
				{
					break;
				}
			}
			catch (const std::exception& e)
			{
				std::throw_with_nested(make_error(tbl_num));
			}
			docwire_log(debug) << "Table processed" << docwire_log_streamable_var(tbl_num);
		}
	}
}
