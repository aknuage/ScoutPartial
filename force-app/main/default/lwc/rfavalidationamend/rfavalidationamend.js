import { LightningElement, api, wire} from 'lwc';
import docxImport from "@salesforce/resourceUrl/docx";
import {loadScript} from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import grabRFAAmendment from "@salesforce/apex/RFAvalidation.getAmendment";
import grabRFAParcels from "@salesforce/apex/RFAvalidation.getAllRelatedParcels";


export default class Rfavalidationamend extends LightningElement {

    @api recordId;
    downloadURL;
    filename;
    getGname;
      getName;
      getRFAName;
      getLeaseVersion;
      getSpouse;
      getLandOwnerInfo;
      getAgreementType;
      getCommentsPrep;
      getRequestType;
      getRejectReason;
      getAmendmentRecordName;
      getTotalAcreage;
      getRFAId;
    getContract;
    getTitleClear;
    getTitleIssues;

    _no_border = {top: {style: "none", size: 0, color: "FFFFFF"},
	bottom: {style: "none", size: 0, color: "FFFFFF"},
	left: {style: "none", size: 0, color: "FFFFFF"},
	right: {style: "none", size: 0, color: "FFFFFF"}};

    connectedCallback(){
        Promise.all([loadScript(this, docxImport)]).then(() =>{
            this.renderButtons();
        });
    }

    renderButtons(){
        this.template.querySelector(".hidden").classList.add("not_hidden");
        this.template.querySelector(".hidden").classList.remove("hidden");
    }

    isLoading;
    async startDocumentGeneration(){
        console.log('Starting doc');
        console.log("RFAAmendId id: " + this.recordId);
            // this.buildDocument();
        this.isLoading = true;
        try {
            const rfaAmend = await grabRFAAmendment({'RFAAmendId': this.recordId});
            this.getRFAId = rfaAmend.Request_for_Amendment__c;

            const rfa = await grabRFAParcels({'RFAId': rfaAmend.Request_for_Agreement__c});
            

            if (rfa === null){
                this.showToastRfaError(); // exit if somehow no records were returned
                return;
            }
            console.log('RFA Parcels ==>', JSON.stringify(rfa, null, '\t'));
            console.log('RFA Amended Parcels =>', JSON.stringify(rfaAmend, null, '\t'));
            console.log('done with that list');
            this.getName = rfaAmend.Project__r.Name??'';
           
            this.getLeaseVersion = rfaAmend.Lease_Version_Document_Name__c??'';
            this.getSpouse= rfaAmend.Spouse_Information__c??'';
            this.getLandOwnerInfo= rfaAmend.Land_Owner_Information__c??'';
            this.getCommentsPrep = rfaAmend.Comments_for_Title_Doc_Prep__c??'';
            this.getAgreementType= rfaAmend.Agreement_Type__c??'';
            this.getRequestType = rfaAmend.Request_Type__c??'';
            this.getTitleClear= rfaAmend.Title_Clear__c??'';
            this.getTitleIssues= rfaAmend.Title_Issues_Comments__c??'';
            this.getAmendmentRecordName= rfaAmend.Name??'';
            this.getRFAName = rfa.Name??'';
            this.getTotalAcreage = rfa.Acreage_Being_Signed__c??'';

          // this.filename = "RFA Amendment.docx";

             this.filename = "RFA Amendment for " + this.getRFAName +".docx";
          //  this.filename = "RFA Summary " + this.getName + " - " + this.getLeaseVersion+".docx";
           this.buildDocument(rfaAmend.Agreement_Parcels__r);
         
         //  this.buildDocument(rfa.Agreement_Parcels__r);
        } catch (error) {
            console.error('error is:  ' + error);
        } finally {
            this.isLoading = false;
        }
    }

    showToastRfaError() {
        const event = new ShowToastEvent({
            title: 'Error Generating RFA Amendment Document',
            variant: 'error',
            mode: 'dismissable',
            message:
                'Null RFA returned.',
        });
        this.dispatchEvent(event);
    }

    buildDocument(RFAParcelsPassed){
        let document = new docx.Document();
        let tableCells = [];
        
        tableCells.push(this.generateRow("Project Name:  ", this.getName));
       // tableCells.push(this.generateRow("Request Type:  ", this.getRequestType));
       
       tableCells.push(this.generateRow("  ", "   ")); 
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Amendment Record:  ", this.getAmendmentRecordName));
        tableCells.push(this.generateRow("Request for Agreement Record:  ", this.getRFAName));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("  ", "   "));
        
        tableCells.push(this.generateRow("Form:  ", this.getLeaseVersion));
        tableCells.push(this.generateRow("Agreement Type:  ", this.getAgreementType));
        tableCells.push(this.generateRow("  ", "   "));

        tableCells.push(this.generateRow("Land owner Information:  ", this.getLandOwnerInfo));
        tableCells.push(this.generateRow("  ", "   "));
     

        tableCells.push(this.generateRow("Spousal information: ", this.getSpouse));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Comments for Title & Doc Prep:  ", this.getCommentsPrep));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Total Acreage:  ", this.getTotalAcreage.toString()));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Detail Parcel Information", "   "));
        
        try{
        if (RFAParcelsPassed.length > 0) {
            RFAParcelsPassed.forEach(rfaparcelsRecord => {
                tableCells.push(this.generateParcelRow(rfaparcelsRecord, 1));
                tableCells.push(this.generateParcelRow(rfaparcelsRecord, 2));
                tableCells.push(this.generateParcelRow(rfaparcelsRecord, 3));
                tableCells.push(this.generateParcelRow(rfaparcelsRecord, 4));
                tableCells.push(this.generateParcelRow(rfaparcelsRecord, 5));
                tableCells.push(this.generateParcelRow(rfaparcelsRecord, 6));
                tableCells.push(this.generateRow("  ", "   "));
                tableCells.push(this.generateRow("  ", "   "));
            });
        }} catch(error){
            tableCells.push(this.generateRow("NO PARCELS FOUND", "   "));
            tableCells.push(this.generateRow("  ", "   "));
            console.log(error)
        }

        tableCells.push(this.generateRow("Title Clear?  ", this.getTitleClear));
        tableCells.push(this.generateRow("Title Issues Comments:  ", this.getTitleIssues));
               
        this.generateTable(document, tableCells);

        this.generateDownloadLink(document);
    }

    generateHeaderRow(){
        let tableHeaderRow = new docx.TableRow({
            children:[
                new docx.TableCell({
                    children: [new docx.Paragraph("Field")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph("Value")],
                    borders: this._no_border
                }) 
            ]
        });

        return tableHeaderRow;
    }

    generateRow(fieldname,fieldValue){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph(fieldname)],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph(fieldValue)],
                    borders: this._no_border
                })
            ]
        });

        return tableRow;
    }

    generateParcelRow(rfaParcelRecord, rowvar){
     if (rowvar ==1){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("PIN:  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["Parcel_ID_Local__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    } else if(rowvar==2){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("Acreage (deed):  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["Deed_Acres__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    } else if(rowvar==3){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("Acreage (GIS):  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["GIS_Acres__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    }
    else if(rowvar==4){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("County:  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["County__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    }
    else if(rowvar==5){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("State: ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["State__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    }
    else if(rowvar==6){
        let getParcelRecordAmend = this.generateTextRun(rfaParcelRecord["Request_For_Amendment_Name__c"]?.toString());
        console.log('Amend info: ' + getParcelRecordAmend[0]);
        if(this.generateTextRun(rfaParcelRecord["Request_For_Amendment_Name__c"]?.toString()) != null){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("Amendment:")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["Request_For_Amendment_Name__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    }
        
    }
        
    }
    generateParcelRowB(rfaParcelRecord){     
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["GIS_Acres__c"].toString())]})],
                    borders: this._no_border
                })
            ]
        });      

        return tableRow;        
    }

    generateTextRun(cellString){
        let textRun = new docx.TextRun({text: cellString});
        //console.log('cellstring: ' & textRun);
        //let textRun = new docx.TextRun({text: cellString, bold: true, size: 10, font: "Calibri"});
        return textRun;
    }

    generateParagraph(cellString){
        let textRun = new docx.TextRun({text: cellString, bold: true, size: 10, font: "Calibri"});
        return textRun;
    }

    generateTable(documentPassed, tableCellsPassed){
        let docTable = new docx.Table({
            rows: tableCellsPassed
        });

        /*
        let setText = new docx.Paragraph({
            style: "text",
            children: [
                new docx.TextRun({
                    text: 'This TEXT is so long that the break is not at the end of the line'
                })
            ]
        });
        */

        documentPassed.addSection({
            //children: [docTable, passedBody]
            children: [docTable]
        });
    }

    generateText(addText) {
    let setText = new docx.Paragraph({
        style: "text",
        children: [
            new docx.TextRun({
                text: this.getGname,
                break: 1,
            }),
           
            new docx.TextRun({
                text: this.getLeaseVersion,
                break: 1,
            }),
          
            new docx.TextRun({
                text: this.getSpouse,
                break: 1,
            }),
              
            new docx.TextRun({
                text: this.getLandOwnerInfo,
                break: 1,
            }),
            new docx.TextRun({
                text: this.getTitleClear,
                break: 1,
            }),
            new docx.TextRun({
                text: this.getTitleIssues,
                break: 1,
            }),
            new docx.TextRun({
                text: this.getAgreementType,
                break: 1,
            })
                
        ]
    });
    
    return setText;
    }

    generateSection(documentPassedA){
        let setText = new docx.Paragraph({
            style: "text",
            children: [
                new docx.TextRun({
                    text: 'This text is shorter that the break is not at the end of the line'
                })
            ]
        });
        return setText;
/*
        documentPassedA.addSection({
            children: [setText]
        });
        */
    }
    // AK: Comment back in if we want two button approach
    /*
    generateDownloadLink(documentPassed){
        docx.Packer.toBase64String(documentPassed).then(textBlob =>{
            this.downloadURL = 'data:application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64,' + textBlob;
            this.template.querySelector(".slds-hide")?.classList.remove("slds-hide");
        });
    }
    */

    generateDownloadLink(documentPassed) {
        docx.Packer.toBase64String(documentPassed).then(base64String => {
            this.downloadURL = `data:application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64,${base64String}`;
            this.triggerDownload(this.downloadURL, this.filename);
        });
    }

    triggerDownload(url, filename) {
        let downloadLink = document.createElement('a');
        document.body.appendChild(downloadLink);
        downloadLink.href = url;
        downloadLink.download = filename;
        downloadLink.click();
        document.body.removeChild(downloadLink);
    }
}