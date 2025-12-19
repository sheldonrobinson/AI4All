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

#ifndef DOCWIRE_DOCX_PARSER_H
#define DOCWIRE_DOCX_PARSER_H

#include "parser.h"
#include "core_export.h"
#include "pimpl.hpp"
#include "tags.hpp"
#include <vector>

namespace docwire
{

class Metadata;

class DOCWIRE_CORE_EXPORT DocxParser : public Parser, public with_pimpl<DocxParser>
{
	private:
		using with_pimpl<DocxParser>::impl;
		using with_pimpl<DocxParser>::renew_impl;
		using with_pimpl<DocxParser>::destroy_impl;
		friend pimpl_impl<DocxParser>;

	public:
		DocxParser();
		DocxParser(DocxParser&&) = default;
		~DocxParser();
		void parse(const data_source& data) override;
		const std::vector<mime_type> supported_mime_types() override
		{
			return { mime_type{"application/vnd.openxmlformats-officedocument.wordprocessingml.document"} };
		}
private:
	void loadDocument(const data_source& data);
	void parseText();
	void parseTables();
};

} // namespace docwire

#endif